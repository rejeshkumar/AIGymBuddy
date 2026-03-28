'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import toast from 'react-hot-toast'
import DashLayout from './layout'
import { useStore } from '@/lib/store'
import { getDailyInsight, logWeight, getWeightHistory } from '@/lib/api'

export default function DashboardPage() {
  const { user, updateUser } = useStore()
  const router = useRouter()
  const [insight, setInsight] = useState('Loading your personalised insight...')
  const [weight, setWeight] = useState(user?.weight_kg || 70)
  const [weightHistory, setWeightHistory] = useState<any[]>([])
  const [loggingWeight, setLoggingWeight] = useState(false)

  useEffect(() => {
    getDailyInsight().then(r => setInsight(r.data.insight)).catch(() => {})
    getWeightHistory().then(r => setWeightHistory(r.data)).catch(() => {})
  }, [])

  const days = ['M','T','W','T','F','S','S']
  const streak = user?.streak || 0

  async function handleLogWeight() {
    setLoggingWeight(true)
    try {
      await logWeight(weight)
      updateUser({ weight_kg: weight })
      toast.success(`Weight logged: ${weight} kg ✓`)
    } catch { toast.error('Could not log weight') }
    finally { setLoggingWeight(false) }
  }

  const weightDelta = weightHistory.length >= 2
    ? (weightHistory[0]?.weight_kg - weightHistory[1]?.weight_kg).toFixed(1)
    : null

  return (
    <DashLayout>
      <div style={{ padding:'20px 20px 0' }} className="fade-up">
        <div style={{ fontSize:12, color:'var(--muted2)' }}>
          {new Date().toLocaleDateString('en-US',{ weekday:'long', month:'long', day:'numeric' })}
        </div>
        <div className="font-syne" style={{ fontSize:24, fontWeight:800, marginTop:4 }}>
          {new Date().getHours() < 12 ? 'Good morning' : new Date().getHours() < 18 ? 'Good afternoon' : 'Good evening'} {user?.name?.split(' ')[0]} ⚡
        </div>
      </div>

      {/* XP + Streak Banner */}
      <div className="fade-up-1" style={{ margin:'16px 20px', background:'linear-gradient(135deg, rgba(232,255,71,0.1), rgba(71,255,184,0.05))', border:'1px solid rgba(232,255,71,0.2)', borderRadius:20, padding:'16px 20px', display:'flex', alignItems:'center', gap:16 }}>
        <span style={{ fontSize:40, lineHeight:1 }}>🔥</span>
        <div style={{ flex:1 }}>
          <div style={{ display:'flex', alignItems:'baseline', gap:6 }}>
            <span className="font-syne" style={{ fontSize:32, fontWeight:800, color:'var(--accent)' }}>{streak}</span>
            <span style={{ fontSize:14, color:'var(--muted2)' }}>day streak</span>
          </div>
          <div style={{ display:'flex', gap:5, marginTop:8 }}>
            {days.map((d,i) => (
              <div key={i} style={{ width:28, height:28, borderRadius:8, display:'flex', alignItems:'center', justifyContent:'center', fontSize:9, fontWeight:600,
                background: i < streak % 7 ? 'var(--accent)' : 'var(--s3)',
                color: i < streak % 7 ? '#060608' : 'var(--muted)' }}>{d}</div>
            ))}
          </div>
        </div>
        <div style={{ textAlign:'right' }}>
          <div className="font-syne" style={{ fontSize:20, fontWeight:800, color:'var(--accent2)' }}>+{streak * 50} XP</div>
          <div style={{ fontSize:10, color:'var(--muted2)' }}>this week</div>
        </div>
      </div>

      {/* Weight Logger */}
      <div className="card fade-up-1" style={{ margin:'0 20px 16px' }}>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:8 }}>
          <span style={{ fontSize:11, textTransform:'uppercase', letterSpacing:1, color:'var(--muted2)' }}>Today's Weight</span>
          {weightDelta && (
            <span style={{ fontSize:12, color: parseFloat(weightDelta) < 0 ? 'var(--accent2)' : 'var(--danger)', fontWeight:500 }}>
              {parseFloat(weightDelta) < 0 ? '▼' : '▲'} {Math.abs(parseFloat(weightDelta))} kg from yesterday
            </span>
          )}
        </div>
        <div style={{ textAlign:'center', padding:'12px 0' }}>
          <span className="font-syne" style={{ fontSize:56, fontWeight:800, color:'var(--accent)' }}>{weight.toFixed(1)}</span>
          <span style={{ fontSize:18, color:'var(--muted2)', marginLeft:4 }}>kg</span>
        </div>
        <div style={{ display:'flex', gap:10, alignItems:'center' }}>
          <button onClick={() => setWeight(w => Math.max(30, Math.round((w-0.1)*10)/10))}
            style={{ width:44, height:44, borderRadius:12, background:'var(--s2)', border:'1px solid var(--border2)', color:'var(--text)', fontSize:20, cursor:'pointer', fontWeight:700 }}>−</button>
          <input type="range" min={30} max={200} step={0.1} value={weight} onChange={e => setWeight(parseFloat(e.target.value))}
            style={{ flex:1, accentColor:'var(--accent)' }}/>
          <button onClick={() => setWeight(w => Math.round((w+0.1)*10)/10)}
            style={{ width:44, height:44, borderRadius:12, background:'var(--s2)', border:'1px solid var(--border2)', color:'var(--text)', fontSize:20, cursor:'pointer', fontWeight:700 }}>+</button>
        </div>
        <button className="btn-primary" onClick={handleLogWeight} disabled={loggingWeight}
          style={{ width:'100%', padding:'13px', fontSize:14, marginTop:12 }}>
          {loggingWeight ? <span className="spinner"/> : 'Log Weight'}
        </button>
      </div>

      {/* AI Coach Bubble */}
      <div className="fade-up-2" onClick={() => router.push('/coach')}
        style={{ margin:'0 20px 16px', background:'var(--s1)', border:'1px solid var(--border2)', borderRadius:20, padding:20, cursor:'pointer', transition:'all 0.2s', position:'relative', overflow:'hidden' }}>
        <div style={{ position:'absolute', right:-20, bottom:-20, width:100, height:100, background:'radial-gradient(circle, rgba(71,255,184,0.08), transparent 70%)', pointerEvents:'none' }}/>
        <div style={{ display:'flex', alignItems:'center', gap:6, marginBottom:10 }}>
          <div style={{ width:6, height:6, borderRadius:'50%', background:'var(--accent2)', animation:'pulse 2s infinite' }}/>
          <span style={{ fontSize:10, letterSpacing:2, textTransform:'uppercase', color:'var(--accent2)', fontWeight:600 }}>AI Coach · Online</span>
        </div>
        <div style={{ fontSize:14, lineHeight:1.65, color:'var(--text)' }}>{insight}</div>
        <div style={{ marginTop:12, fontSize:13, color:'var(--accent)', fontWeight:500 }}>Start coaching session →</div>
      </div>

      {/* Quick Actions */}
      <div className="fade-up-2" style={{ margin:'0 20px 16px' }}>
        <div style={{ fontSize:11, textTransform:'uppercase', letterSpacing:1, color:'var(--muted2)', marginBottom:12 }}>Quick Actions</div>
        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:10 }}>
          {[
            { icon:'💪', label:'Generate Workout', sub:'AI-powered plan', href:'/workout', color:'var(--accent)' },
            { icon:'🤖', label:'Talk to Coach', sub:'Real AI coaching', href:'/coach', color:'var(--accent2)' },
            { icon:'❤️', label:'Log Vitals', sub:'Track your health', href:'/health', color:'#ff6b8a' },
            { icon:'📊', label:'View Progress', sub:'Your transformation', href:'/progress', color:'var(--accent3)' },
          ].map(a => (
            <div key={a.label} onClick={() => router.push(a.href)}
              style={{ background:'var(--s1)', border:'1px solid var(--border)', borderRadius:16, padding:'16px', cursor:'pointer', transition:'all 0.2s' }}
              onMouseEnter={e => (e.currentTarget.style.borderColor = a.color)}
              onMouseLeave={e => (e.currentTarget.style.borderColor = 'var(--border)')}>
              <div style={{ fontSize:24, marginBottom:8 }}>{a.icon}</div>
              <div style={{ fontSize:13, fontWeight:500 }}>{a.label}</div>
              <div style={{ fontSize:11, color:'var(--muted2)', marginTop:2 }}>{a.sub}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Stats Row */}
      <div className="fade-up-3" style={{ display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap:10, margin:'0 20px 24px' }}>
        {[
          { label:'Workouts', value: user?.total_workouts || 0 },
          { label:'XP Earned', value: (user?.xp || 0).toLocaleString() },
          { label:'Streak', value: `${streak}d` },
        ].map(s => (
          <div key={s.label} style={{ background:'var(--s1)', border:'1px solid var(--border)', borderRadius:14, padding:'14px 12px', textAlign:'center' }}>
            <div className="font-syne" style={{ fontSize:22, fontWeight:800, color:'var(--accent)' }}>{s.value}</div>
            <div style={{ fontSize:11, color:'var(--muted2)', marginTop:2 }}>{s.label}</div>
          </div>
        ))}
      </div>
    </DashLayout>
  )
}
