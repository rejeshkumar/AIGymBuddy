'use client'
import { useState, useRef, useEffect, useCallback } from 'react'
import toast from 'react-hot-toast'
import DashLayout from '../dashboard/layout'
import { chatWithCoach } from '@/lib/api'

const EXERCISES: Record<string, { repJoint:[number,number,number]; downAngle:number; upAngle:number; cues:string[] }> = {
  'Squat':          { repJoint:[23,25,27], downAngle:90,  upAngle:160, cues:['Chest up','Knees out','Drive through heels'] },
  'Push-up':        { repJoint:[11,13,15], downAngle:90,  upAngle:160, cues:['Body straight','Elbows at 45°','Full range'] },
  'Bicep Curl':     { repJoint:[11,13,15], downAngle:160, upAngle:50,  cues:['No swinging','Full extension','Squeeze at top'] },
  'Lunge':          { repJoint:[23,25,27], downAngle:90,  upAngle:160, cues:['Knee over ankle','Upright torso','Back knee down'] },
  'Shoulder Press': { repJoint:[11,13,15], downAngle:90,  upAngle:160, cues:['Core tight','Full lockout','Straight path'] },
  'Deadlift':       { repJoint:[11,23,25], downAngle:60,  upAngle:160, cues:['Neutral spine','Bar close','Hip hinge first'] },
}

function calcAngle(a:{x:number,y:number}, b:{x:number,y:number}, c:{x:number,y:number}): number {
  const r = Math.atan2(c.y-b.y, c.x-b.x) - Math.atan2(a.y-b.y, a.x-b.x)
  let angle = Math.abs(r * 180 / Math.PI)
  if (angle > 180) angle = 360 - angle
  return Math.round(angle)
}

interface Msg { role:'user'|'assistant'; content:string }

export default function CoachPage() {
  const videoRef  = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const poseRef   = useRef<any>(null)
  const streamRef = useRef<MediaStream|null>(null)
  const rafRef    = useRef<number>(0)
  const stateRef  = useRef({ count:0, phase:'up' as 'up'|'down', history:[] as number[] })

  const [exercise,      setExercise]      = useState('Squat')
  const [reps,          setReps]          = useState(0)
  const [formScore,     setFormScore]     = useState<number|null>(null)
  const [angle,         setAngle]         = useState<number|null>(null)
  const [phase,         setPhase]         = useState<'up'|'down'|null>(null)
  const [feedback,      setFeedback]      = useState('')
  const [isCoaching,    setIsCoaching]    = useState(false)
  const [cameraOn,      setCameraOn]      = useState(false)
  const [cameraLoading, setCameraLoading] = useState(false)
  const [messages,      setMessages]      = useState<Msg[]>([{ role:'assistant', content:"FORGE AI Coach with real MediaPipe pose detection. Enable your camera, pick an exercise, press Start — I'll count every rep and score your form live. 💪" }])
  const [input,         setInput]         = useState('')
  const [chatLoading,   setChatLoading]   = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)

  const isCoachingRef = useRef(false)
  const exerciseRef   = useRef(exercise)

  useEffect(() => { isCoachingRef.current = isCoaching }, [isCoaching])
  useEffect(() => { exerciseRef.current = exercise },      [exercise])
  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior:'smooth' }) }, [messages])

  useEffect(() => {
    const scripts = [
      'https://cdn.jsdelivr.net/npm/@mediapipe/pose/pose.js',
    ]
    const els = scripts.map(src => {
      const s = document.createElement('script')
      s.src = src; s.crossOrigin = 'anonymous'
      document.head.appendChild(s)
      return s
    })
    return () => els.forEach(s => { if (document.head.contains(s)) document.head.removeChild(s) })
  }, [])

  const addMsg = useCallback((role:'ai'|'user', content:string) => {
    setMessages(m => [...m, { role: role==='ai'?'assistant':'user', content }])
  }, [])

  const onResults = useCallback((results:any) => {
    const canvas = canvasRef.current
    const video  = videoRef.current
    if (!canvas || !video) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    canvas.width  = video.videoWidth  || 640
    canvas.height = video.videoHeight || 480

    ctx.save()
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    ctx.drawImage(results.image, 0, 0, canvas.width, canvas.height)

    const lm = results.poseLandmarks
    if (!lm || !isCoachingRef.current) { ctx.restore(); return }

    const W = canvas.width
    const H = canvas.height

    // Draw skeleton
    const CONNS = [[11,12],[11,13],[13,15],[12,14],[14,16],[11,23],[12,24],[23,24],[23,25],[25,27],[24,26],[26,28]]
    ctx.strokeStyle = 'rgba(71,255,184,0.8)'; ctx.lineWidth = 3
    CONNS.forEach(([a,b]) => {
      if (lm[a]?.visibility > 0.4 && lm[b]?.visibility > 0.4) {
        ctx.beginPath(); ctx.moveTo(lm[a].x*W, lm[a].y*H); ctx.lineTo(lm[b].x*W, lm[b].y*H); ctx.stroke()
      }
    })
    lm.forEach((p:any) => {
      if (p.visibility > 0.4) {
        ctx.beginPath(); ctx.arc(p.x*W, p.y*H, 5, 0, 2*Math.PI)
        ctx.fillStyle = '#e8ff47'; ctx.fill()
      }
    })

    const ex = EXERCISES[exerciseRef.current]
    if (!ex) { ctx.restore(); return }
    const [ai,bi,ci] = ex.repJoint

    if (lm[ai]?.visibility>0.4 && lm[bi]?.visibility>0.4 && lm[ci]?.visibility>0.4) {
      const a = calcAngle(lm[ai], lm[bi], lm[ci])
      setAngle(a)

      ctx.fillStyle='#e8ff47'; ctx.font='bold 18px sans-serif'
      ctx.fillText(`${a}°`, lm[bi].x*W+10, lm[bi].y*H-10)

      const st = stateRef.current
      st.history.push(a)
      if (st.history.length > 8) st.history.shift()
      const smooth = st.history.reduce((x,y)=>x+y,0) / st.history.length

      if (st.phase==='up' && smooth < ex.downAngle+20) {
        st.phase = 'down'; setPhase('down')
        setFeedback(ex.cues[st.count % ex.cues.length])
      } else if (st.phase==='down' && smooth > ex.upAngle-20) {
        st.phase = 'up'; st.count++; setPhase('up'); setReps(st.count)
        if (st.count===5)  addMsg('ai', `5 reps! Great work. ${ex.cues[0]}`)
        if (st.count===10) addMsg('ai', `10 reps! Keep that form! 🔥`)
        if (st.count===15) addMsg('ai', `15! Last 5 — dig deep! 💪`)
        if (st.count===20) { addMsg('ai', `20 reps done! Rest 60–90 sec. Beast mode. 🏆`); setIsCoaching(false) }
      }

      // Posture score from symmetry
      const sym = Math.abs(
        calcAngle(lm[ai], lm[bi], lm[ci]) -
        calcAngle(lm[ai%2===1?ai+1:ai-1], lm[bi%2===1?bi+1:bi-1], lm[ci%2===1?ci+1:ci-1])
      )
      const score = Math.max(0, Math.min(100, 100 - sym * 1.5))
      setFormScore(Math.round(score))
    }

    ctx.restore()
  }, [addMsg])

  async function startCamera() {
    setCameraLoading(true)
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video:{ facingMode:'user', width:{ideal:640}, height:{ideal:480} } })
      streamRef.current = stream
      if (videoRef.current) { videoRef.current.srcObject = stream; await videoRef.current.play() }

      let tries = 0
      while (!(window as any).Pose && tries++ < 30) await new Promise(r=>setTimeout(r,500))
      if (!(window as any).Pose) { toast.error('MediaPipe failed to load. Refresh and try again.'); setCameraLoading(false); return }

      const pose = new (window as any).Pose({ locateFile:(f:string)=>`https://cdn.jsdelivr.net/npm/@mediapipe/pose/${f}` })
      pose.setOptions({ modelComplexity:1, smoothLandmarks:true, enableSegmentation:false, minDetectionConfidence:0.5, minTrackingConfidence:0.5 })
      pose.onResults(onResults)
      poseRef.current = pose

      const loop = async () => {
        if (videoRef.current && poseRef.current && streamRef.current?.active) {
          await poseRef.current.send({ image: videoRef.current })
          rafRef.current = requestAnimationFrame(loop)
        }
      }
      rafRef.current = requestAnimationFrame(loop)
      setCameraOn(true)
      addMsg('ai', `Camera live! I can see you. Pick an exercise and tap Start — rep counting begins automatically.`)
    } catch (e:any) {
      toast.error(e.name==='NotAllowedError' ? 'Camera permission denied' : 'Camera error: '+e.message)
    }
    setCameraLoading(false)
  }

  function stopCamera() {
    cancelAnimationFrame(rafRef.current)
    streamRef.current?.getTracks().forEach(t=>t.stop())
    streamRef.current = null; poseRef.current = null
    setCameraOn(false); setIsCoaching(false)
    const ctx = canvasRef.current?.getContext('2d')
    if (ctx && canvasRef.current) ctx.clearRect(0,0,canvasRef.current.width,canvasRef.current.height)
  }

  function startCoaching() {
    if (!cameraOn) { toast.error('Enable camera first'); return }
    stateRef.current = { count:0, phase:'up', history:[] }
    setReps(0); setFormScore(null); setPhase(null); setFeedback(''); setIsCoaching(true)
    addMsg('ai', `Tracking ${exercise}. Get into position — counting starts on your first rep. ${EXERCISES[exercise]?.cues[0]}`)
  }

  function stopCoaching() {
    setIsCoaching(false)
    const n = stateRef.current.count
    if (n>0) addMsg('ai', `Set done! ${n} reps of ${exercise}. Form: ${formScore}%. Rest up 💪`)
  }

  function reset() {
    stateRef.current = { count:0, phase:'up', history:[] }
    setReps(0); setFormScore(null); setPhase(null); setFeedback('')
    if (isCoaching) setIsCoaching(false)
  }

  async function send() {
    if (!input.trim()||chatLoading) return
    const txt = input.trim(); addMsg('user',txt); setInput(''); setChatLoading(true)
    try { const r = await chatWithCoach(txt, messages.slice(-6)); addMsg('ai',r.data.message) }
    catch { toast.error('Coach unavailable') }
    setChatLoading(false)
  }

  const scoreColor = !formScore ? 'var(--muted2)' : formScore>80 ? 'var(--accent2)' : formScore>60 ? 'var(--accent)' : 'var(--danger)'

  return (
    <DashLayout>
      <div style={{ display:'flex', flexDirection:'column', minHeight:'calc(100vh - 80px)' }}>

        {/* HEADER */}
        <div style={{ padding:'14px 16px', borderBottom:'1px solid var(--border)', display:'flex', alignItems:'center', gap:10, flexShrink:0 }}>
          <div style={{ width:40, height:40, borderRadius:12, background:'linear-gradient(135deg,var(--accent2),var(--accent))', display:'flex', alignItems:'center', justifyContent:'center', fontSize:18 }}>🤖</div>
          <div style={{ flex:1 }}>
            <div className="font-syne" style={{ fontSize:16, fontWeight:700 }}>FORGE AI Coach</div>
            <div style={{ fontSize:11, color: cameraOn?'var(--accent2)':'var(--muted2)', display:'flex', alignItems:'center', gap:4 }}>
              <div style={{ width:5, height:5, borderRadius:'50%', background:cameraOn?'var(--accent2)':'var(--muted)', animation:cameraOn?'pulse 2s infinite':'none' }}/>
              {cameraOn ? 'MediaPipe Pose — Real CV — On Device' : 'Camera off'}
            </div>
          </div>
          {!cameraOn
            ? <button onClick={startCamera} disabled={cameraLoading}
                style={{ padding:'8px 16px', borderRadius:20, border:'none', background:'var(--accent)', color:'#060608', cursor:'pointer', fontWeight:600, fontSize:13, fontFamily:'DM Sans,sans-serif', opacity:cameraLoading?0.6:1 }}>
                {cameraLoading ? 'Loading...' : '📷 Enable'}
              </button>
            : <button onClick={stopCamera}
                style={{ padding:'8px 16px', borderRadius:20, border:'1px solid rgba(255,71,87,0.3)', background:'rgba(255,71,87,0.1)', color:'var(--danger)', cursor:'pointer', fontWeight:600, fontSize:13, fontFamily:'DM Sans,sans-serif' }}>
                Off
              </button>
          }
        </div>

        {/* CAMERA CANVAS */}
        <div style={{ position:'relative', background:'#0a0a0f', margin:'12px 16px', borderRadius:18, overflow:'hidden', aspectRatio:'4/3', maxHeight:300, flexShrink:0 }}>
          <video ref={videoRef} style={{ position:'absolute', inset:0, width:'100%', height:'100%', objectFit:'cover', opacity:0 }} playsInline muted/>
          <canvas ref={canvasRef} style={{ position:'absolute', inset:0, width:'100%', height:'100%', objectFit:'cover' }}/>

          {!cameraOn && (
            <div style={{ position:'absolute', inset:0, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:10 }}>
              <div style={{ fontSize:40 }}>📷</div>
              <div style={{ fontSize:13, color:'var(--muted2)', textAlign:'center', lineHeight:1.6 }}>Real MediaPipe Pose Detection<br/><span style={{ fontSize:11, color:'var(--muted)' }}>On-device · Private · Zero upload</span></div>
              <button onClick={startCamera} disabled={cameraLoading}
                style={{ padding:'10px 24px', borderRadius:20, border:'none', background:'var(--accent)', color:'#060608', cursor:'pointer', fontWeight:600, fontSize:13, fontFamily:'DM Sans,sans-serif' }}>
                {cameraLoading?'Loading MediaPipe...':'Enable Camera'}
              </button>
            </div>
          )}

          {cameraOn && <>
            <div style={{ position:'absolute', top:10, right:10, background:'rgba(6,6,8,0.88)', borderRadius:12, padding:'8px 12px', textAlign:'center' }}>
              <div className="font-syne" style={{ fontSize:32, fontWeight:800, color:'var(--accent)', lineHeight:1 }}>{reps}</div>
              <div style={{ fontSize:9, letterSpacing:1, textTransform:'uppercase', color:'var(--muted2)' }}>REPS</div>
            </div>
            {formScore!==null && (
              <div style={{ position:'absolute', bottom:10, right:10, background:'rgba(6,6,8,0.88)', borderRadius:12, padding:'7px 11px', textAlign:'center' }}>
                <div className="font-syne" style={{ fontSize:20, fontWeight:800, color:scoreColor, lineHeight:1 }}>{formScore}%</div>
                <div style={{ fontSize:9, letterSpacing:1, textTransform:'uppercase', color:'var(--muted2)' }}>FORM</div>
              </div>
            )}
            {angle!==null && (
              <div style={{ position:'absolute', bottom:10, left:10, background:'rgba(6,6,8,0.88)', borderRadius:10, padding:'6px 10px' }}>
                <div style={{ fontSize:10, color:'var(--muted2)' }}>Angle</div>
                <div className="font-syne" style={{ fontSize:16, fontWeight:700, color:'var(--accent2)' }}>{angle}°</div>
              </div>
            )}
            {phase && (
              <div style={{ position:'absolute', top:10, left:10, background:phase==='down'?'rgba(232,255,71,0.15)':'rgba(71,255,184,0.15)', border:`1px solid ${phase==='down'?'rgba(232,255,71,0.3)':'rgba(71,255,184,0.3)'}`, borderRadius:10, padding:'4px 10px' }}>
                <div style={{ fontSize:11, fontWeight:700, color:phase==='down'?'var(--accent)':'var(--accent2)' }}>{phase==='down'?'▼ DOWN':'▲ UP'}</div>
              </div>
            )}
          </>}
        </div>

        {/* EXERCISE TABS */}
        <div style={{ padding:'0 16px 10px', flexShrink:0 }}>
          <div style={{ display:'flex', gap:7, overflowX:'auto', paddingBottom:6, scrollbarWidth:'none' }}>
            {Object.keys(EXERCISES).map(ex => (
              <button key={ex} onClick={()=>{setExercise(ex);reset()}}
                style={{ flexShrink:0, padding:'6px 13px', borderRadius:20, border:`1px solid ${exercise===ex?'var(--accent)':'var(--border2)'}`,
                  background:exercise===ex?'var(--accent)':'var(--s2)', color:exercise===ex?'#060608':'var(--muted2)',
                  cursor:'pointer', fontSize:12, fontWeight:exercise===ex?600:400, whiteSpace:'nowrap', fontFamily:'DM Sans,sans-serif' }}>{ex}</button>
            ))}
          </div>
          <div style={{ display:'flex', gap:8, alignItems:'center', marginTop:8 }}>
            {feedback && <div style={{ flex:1, fontSize:12, color:'var(--accent2)', padding:'7px 11px', background:'rgba(71,255,184,0.06)', borderRadius:10, border:'1px solid rgba(71,255,184,0.15)' }}>💡 {feedback}</div>}
            <button onClick={reset}
              style={{ padding:'7px 12px', borderRadius:20, border:'1px solid var(--border2)', background:'var(--s2)', color:'var(--muted2)', cursor:'pointer', fontSize:12, fontFamily:'DM Sans,sans-serif', whiteSpace:'nowrap' }}>Reset</button>
            <button onClick={isCoaching?stopCoaching:startCoaching}
              style={{ padding:'9px 20px', borderRadius:20, border:'none', cursor:'pointer', fontFamily:'DM Sans,sans-serif', fontWeight:600, fontSize:13, whiteSpace:'nowrap',
                background:isCoaching?'rgba(255,71,87,0.15)':'var(--accent)', color:isCoaching?'var(--danger)':'#060608',
                outline:isCoaching?'1px solid rgba(255,71,87,0.3)':'none' }}>
              {isCoaching?'⏹ Stop':'▶ Start'}
            </button>
          </div>
        </div>

        {/* CHAT */}
        <div style={{ flex:1, display:'flex', flexDirection:'column', borderTop:'1px solid var(--border)' }}>
          <div style={{ flex:1, overflowY:'auto', padding:'12px 16px', display:'flex', flexDirection:'column', gap:10, scrollbarWidth:'none', minHeight:160 }}>
            {messages.map((m,i)=>(
              <div key={i} style={{ maxWidth:'84%', alignSelf:m.role==='user'?'flex-end':'flex-start' }}>
                <div style={{ padding:'9px 13px', borderRadius:14, fontSize:13, lineHeight:1.6,
                  background:m.role==='user'?'var(--accent)':'var(--s2)', color:m.role==='user'?'#060608':'var(--text)',
                  borderBottomRightRadius:m.role==='user'?3:14, borderBottomLeftRadius:m.role==='assistant'?3:14,
                  border:m.role==='assistant'?'1px solid var(--border)':'none', fontWeight:m.role==='user'?500:400 }}>{m.content}</div>
              </div>
            ))}
            {chatLoading && (
              <div style={{ alignSelf:'flex-start', background:'var(--s2)', border:'1px solid var(--border)', borderRadius:14, borderBottomLeftRadius:3, padding:'10px 14px', display:'flex', gap:4 }}>
                {[0,1,2].map(i=><div key={i} style={{ width:6, height:6, borderRadius:'50%', background:'var(--muted)', animation:`pulse 1.2s ${i*0.2}s infinite` }}/>)}
              </div>
            )}
            <div ref={bottomRef}/>
          </div>
          <div style={{ padding:'10px 16px 14px', borderTop:'1px solid var(--border)', display:'flex', gap:8 }}>
            <input className="forge-input" style={{ flex:1, padding:'10px 14px', fontSize:13 }}
              placeholder="Ask your AI coach..." value={input}
              onChange={e=>setInput(e.target.value)} onKeyDown={e=>e.key==='Enter'&&send()}/>
            <button onClick={send} disabled={chatLoading||!input.trim()}
              style={{ width:40, height:40, borderRadius:'50%', background:'var(--accent)', border:'none', cursor:'pointer', fontSize:16, display:'flex', alignItems:'center', justifyContent:'center', opacity:(!input.trim()||chatLoading)?0.4:1 }}>↑</button>
          </div>
        </div>
      </div>
    </DashLayout>
  )
}
