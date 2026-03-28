'use client'
import { useState, useRef, useEffect } from 'react'
import toast from 'react-hot-toast'
import DashLayout from '../dashboard/layout'
import { chatWithCoach, getFormFeedback } from '@/lib/api'

const EXERCISES = ['Squat','Push-up','Deadlift','Pull-up','Lunge','Plank','Bicep Curl','OHP','Bench Press','Romanian DL']

interface Msg { role: 'user'|'assistant'; content: string }

export default function CoachPage() {
  const [messages, setMessages] = useState<Msg[]>([
    { role:'assistant', content:"I'm your FORGE AI Coach — powered by real AI, not scripts. Tell me what you're working on today, ask about your form, nutrition, recovery, or just start a coaching session. I have your full profile and health data. Let's get to work. 💪" }
  ])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [exercise, setExercise] = useState('Squat')
  const [reps, setReps] = useState(0)
  const [isCoaching, setIsCoaching] = useState(false)
  const [formScore, setFormScore] = useState<number|null>(null)
  const [formFeedback, setFormFeedback] = useState('')
  const [coachingInterval, setCoachingInterval] = useState<any>(null)
  const bottomRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior:'smooth' }) }, [messages])

  async function send() {
    if (!input.trim() || loading) return
    const userMsg: Msg = { role:'user', content: input.trim() }
    setMessages(m => [...m, userMsg])
    setInput('')
    setLoading(true)
    try {
      const history = messages.slice(-8)
      const r = await chatWithCoach(userMsg.content, history)
      setMessages(m => [...m, { role:'assistant', content: r.data.message }])
    } catch { toast.error('Coach unavailable — check API connection') }
    finally { setLoading(false) }
  }

  async function startCoaching() {
    setIsCoaching(true)
    setReps(0)
    setFormScore(null)
    toast.success(`Coaching ${exercise} — get into position!`)

    let repCount = 0
    const interval = setInterval(async () => {
      repCount++
      setReps(repCount)
      try {
        const r = await getFormFeedback(exercise, repCount)
        setFormScore(r.data.score)
        setFormFeedback(r.data.feedback)
        if (!r.data.safe_to_continue) {
          setMessages(m => [...m, { role:'assistant', content:`⚠️ Stop! ${r.data.feedback} Fix your form before continuing.` }])
        } else if (repCount % 5 === 0) {
          setMessages(m => [...m, { role:'assistant', content:`${repCount} reps! ${r.data.tip} Form score: ${r.data.score}%` }])
        }
      } catch {}
    }, 3000)
    setCoachingInterval(interval)
  }

  function stopCoaching() {
    setIsCoaching(false)
    if (coachingInterval) clearInterval(coachingInterval)
    if (reps > 0) {
      setMessages(m => [...m, { role:'assistant', content:`Set complete! ${reps} reps of ${exercise}. Average form score: ${formScore}%. Rest up, then go again. 💪` }])
    }
  }

  return (
    <DashLayout>
      <div style={{ display:'flex', flexDirection:'column', height:'calc(100vh - 80px)' }}>
        {/* Header */}
        <div style={{ padding:'20px', borderBottom:'1px solid var(--border)', flexShrink:0 }}>
          <div style={{ display:'flex', alignItems:'center', gap:14 }}>
            <div style={{ width:48, height:48, borderRadius:16, background:'linear-gradient(135deg, var(--accent2), var(--accent))', display:'flex', alignItems:'center', justifyContent:'center', fontSize:22 }}>🤖</div>
            <div style={{ flex:1 }}>
              <div className="font-syne" style={{ fontSize:18, fontWeight:700 }}>FORGE AI Coach</div>
              <div style={{ display:'flex', alignItems:'center', gap:6, fontSize:12, color:'var(--accent2)' }}>
                <div style={{ width:6, height:6, borderRadius:'50%', background:'var(--accent2)', animation:'pulse 2s infinite' }}/>
                Real AI · Full context · Always on
              </div>
            </div>
          </div>
        </div>

        {/* Rep Counter + Exercise Selector */}
        <div style={{ padding:'12px 20px', borderBottom:'1px solid var(--border)', flexShrink:0 }}>
          <div style={{ display:'flex', gap:8, overflowX:'auto', paddingBottom:8, marginBottom:10 }}>
            {EXERCISES.map(ex => (
              <button key={ex} onClick={() => { setExercise(ex); setReps(0); setFormScore(null) }}
                style={{ flexShrink:0, padding:'6px 14px', borderRadius:20, border:`1px solid ${exercise===ex ? 'var(--accent)' : 'var(--border2)'}`,
                  background: exercise===ex ? 'var(--accent)' : 'var(--s2)',
                  color: exercise===ex ? '#060608' : 'var(--muted2)',
                  cursor:'pointer', fontSize:12, fontWeight: exercise===ex ? 600 : 400, whiteSpace:'nowrap' }}>{ex}</button>
            ))}
          </div>

          <div style={{ display:'flex', alignItems:'center', gap:12 }}>
            <div style={{ flex:1, background:'var(--s2)', border:'1px solid var(--border)', borderRadius:14, padding:'12px 16px', display:'flex', alignItems:'center', gap:12 }}>
              <div style={{ textAlign:'center' }}>
                <div className="font-syne" style={{ fontSize:32, fontWeight:800, color:'var(--accent)', lineHeight:1 }}>{reps}</div>
                <div style={{ fontSize:9, letterSpacing:1, textTransform:'uppercase', color:'var(--muted2)' }}>Reps</div>
              </div>
              {formScore !== null && (
                <>
                  <div style={{ width:'1px', height:36, background:'var(--border)' }}/>
                  <div style={{ textAlign:'center' }}>
                    <div className="font-syne" style={{ fontSize:24, fontWeight:800, color: formScore > 85 ? 'var(--accent2)' : formScore > 70 ? 'var(--accent)' : 'var(--danger)', lineHeight:1 }}>{formScore}%</div>
                    <div style={{ fontSize:9, letterSpacing:1, textTransform:'uppercase', color:'var(--muted2)' }}>Form</div>
                  </div>
                  {formFeedback && (
                    <>
                      <div style={{ width:'1px', height:36, background:'var(--border)' }}/>
                      <div style={{ fontSize:12, color:'var(--muted2)', flex:1, lineHeight:1.4 }}>{formFeedback}</div>
                    </>
                  )}
                </>
              )}
            </div>
            <button onClick={isCoaching ? stopCoaching : startCoaching}
              style={{ padding:'12px 16px', borderRadius:14, cursor:'pointer', fontFamily:'DM Sans,sans-serif', fontWeight:600, fontSize:13, transition:'all 0.2s',
                background: isCoaching ? 'rgba(255,71,87,0.15)' : 'var(--accent)',
                color: isCoaching ? 'var(--danger)' : '#060608',
                border: isCoaching ? '1px solid rgba(255,71,87,0.3)' : 'none' } as any}>
              {isCoaching ? '⏹ Stop' : '▶ Start'}
            </button>
          </div>
        </div>

        {/* Messages */}
        <div style={{ flex:1, overflowY:'auto', padding:'16px 20px', display:'flex', flexDirection:'column', gap:12 }}>
          {messages.map((m, i) => (
            <div key={i} style={{ maxWidth:'82%', alignSelf: m.role==='user' ? 'flex-end' : 'flex-start' }}>
              <div style={{ padding:'10px 14px', borderRadius:16, fontSize:14, lineHeight:1.65,
                background: m.role==='user' ? 'var(--accent)' : 'var(--s2)',
                color: m.role==='user' ? '#060608' : 'var(--text)',
                borderBottomRightRadius: m.role==='user' ? 4 : 16,
                borderBottomLeftRadius: m.role==='assistant' ? 4 : 16,
                border: m.role==='assistant' ? '1px solid var(--border)' : 'none',
                fontWeight: m.role==='user' ? 500 : 400 }}>
                {m.content}
              </div>
            </div>
          ))}
          {loading && (
            <div style={{ alignSelf:'flex-start', background:'var(--s2)', border:'1px solid var(--border)', borderRadius:16, borderBottomLeftRadius:4, padding:'12px 16px' }}>
              <div style={{ display:'flex', gap:4 }}>
                {[0,1,2].map(i => <div key={i} style={{ width:6, height:6, borderRadius:'50%', background:'var(--muted)', animation:`pulse 1.2s ${i*0.2}s infinite` }}/>)}
              </div>
            </div>
          )}
          <div ref={bottomRef}/>
        </div>

        {/* Input */}
        <div style={{ padding:'12px 20px 16px', borderTop:'1px solid var(--border)', display:'flex', gap:10, flexShrink:0 }}>
          <input ref={inputRef} className="forge-input" style={{ flex:1, padding:'11px 14px', fontSize:14 }}
            placeholder="Ask your AI coach anything..."
            value={input} onChange={e => setInput(e.target.value)}
            onKeyDown={e => e.key==='Enter' && send()}/>
          <button onClick={send} disabled={loading || !input.trim()}
            style={{ width:44, height:44, borderRadius:'50%', background:'var(--accent)', border:'none', cursor:'pointer', fontSize:18, display:'flex', alignItems:'center', justifyContent:'center', opacity: (!input.trim()||loading) ? 0.5 : 1 }}>↑</button>
        </div>
      </div>
    </DashLayout>
  )
}
