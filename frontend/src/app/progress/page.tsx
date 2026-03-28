'use client'
import { useEffect, useState } from 'react'
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import DashLayout from '../dashboard/layout'
import { useStore } from '@/lib/store'
import { getWeightHistory, getWorkoutHistory } from '@/lib/api'

const ACHIEVEMENTS = [
  { icon:'🔥', name:'First Streak', desc:'3 day streak', xp:100 },
  { icon:'💪', name:'10 Workouts', desc:'Dedicated athlete', xp:500 },
  { icon:'🧬', name:'Bio Hacker', desc:'Health data logged', xp:200 },
  { icon:'⚡', name:'AI Native', desc:'Used AI coach', xp:150 },
  { icon:'🏆', name:'Month Strong', desc:'30 day streak', xp:1000 },
  { icon:'🌅', name:'Early Bird', desc:'5am workout', xp:300 },
]

export default function ProgressPage() {
  const { user } = useStore()
  const [weights, setWeights]   = useState<any[]>([])
  const [workouts, setWorkouts] = useState<any[]>([])

  useEffect(() => {
    getWeightHistory().then(r => setWeights(r.data.slice().reverse())).catch(() => {})
    getWorkoutHistory().then(r => setWorkouts(r.data)).catch(() => {})
  }, [])

  const weightDelta = weights.length >= 2
    ? (weights[weights.length-1]?.weight_kg - weights[0]?.weight_kg).toFixed(1)
    : null

  const totalKcal = workouts.filter(w => w.completed).reduce((a, w) => a + (w.kcal_burned || 0), 0)

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload?.length) {
      return (
        <div style={{ background:'var(--s2)', border:'1px solid var(--border2)', borderRadius:10, padding:'8px 12px', fontSize:12 }}>
          <div style={{ color:'var(--muted2)' }}>{payload[0]?.payload?.date}</div>
          <div style={{ color:'var(--accent)', fontWeight:600 }}>{payload[0]?.value} kg</div>
        </div>
      )
    }
    return null
  }

  return (
    <DashLayout>
      <div style={{ padding:'20px 20px 0' }}>
        <div style={{ fontSize:11, textTransform:'uppercase', letterSpacing:1, color:'var(--muted2)' }}>Your Journey</div>
        <div className="font-syne fade-up" style={{ fontSize:28, fontWeight:800, marginBottom:20 }}>Progress</div>

        {/* Stats */}
        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap:10, marginBottom:20 }}>
          {[
            { label:'Workouts', value: user?.total_workouts || 0, color:'var(--accent)' },
            { label:'Streak', value: `${user?.streak || 0}d`, color:'var(--accent2)' },
            { label:'Total XP', value: (user?.xp || 0).toLocaleString(), color:'var(--accent3)' },
          ].map(s => (
            <div key={s.label} style={{ background:'var(--s1)', border:'1px solid var(--border)', borderRadius:14, padding:'14px 12px', textAlign:'center' }}>
              <div className="font-syne" style={{ fontSize:22, fontWeight:800, color:s.color }}>{s.value}</div>
              <div style={{ fontSize:11, color:'var(--muted2)', marginTop:2 }}>{s.label}</div>
            </div>
          ))}
        </div>

        {/* Weight Chart */}
        <div className="card fade-up-1" style={{ marginBottom:16 }}>
          <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:16 }}>
            <div className="font-syne" style={{ fontSize:16, fontWeight:700 }}>Weight Trend</div>
            {weightDelta && (
              <span className={parseFloat(weightDelta) < 0 ? 'chip chip-green' : 'chip chip-red'}>
                {parseFloat(weightDelta) < 0 ? '▼' : '▲'} {Math.abs(parseFloat(weightDelta))} kg
              </span>
            )}
          </div>
          {weights.length < 2 ? (
            <div style={{ textAlign:'center', padding:'24px 0', color:'var(--muted2)', fontSize:13 }}>Log your weight daily to see your trend chart.</div>
          ) : (
            <ResponsiveContainer width="100%" height={160}>
              <LineChart data={weights}>
                <XAxis dataKey="date" tick={{ fontSize:10, fill:'var(--muted2)' }} tickFormatter={d => d.slice(5)}/>
                <YAxis domain={['auto','auto']} tick={{ fontSize:10, fill:'var(--muted2)' }} width={36}/>
                <Tooltip content={<CustomTooltip/>}/>
                <Line type="monotone" dataKey="weight_kg" stroke="var(--accent)" strokeWidth={2.5} dot={{ fill:'var(--accent)', r:3 }} activeDot={{ r:5 }}/>
              </LineChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* Calories */}
        {totalKcal > 0 && (
          <div className="card fade-up-1" style={{ marginBottom:16, display:'flex', alignItems:'center', gap:16 }}>
            <span style={{ fontSize:32 }}>🔥</span>
            <div>
              <div className="font-syne" style={{ fontSize:24, fontWeight:800, color:'var(--accent3)' }}>{totalKcal.toLocaleString()}</div>
              <div style={{ fontSize:12, color:'var(--muted2)' }}>Total calories burned from completed workouts</div>
            </div>
          </div>
        )}

        {/* Achievements */}
        <div style={{ fontSize:14, fontWeight:600, marginBottom:12, marginTop:4 }}>Achievements</div>
        <div style={{ display:'flex', gap:10, overflowX:'auto', paddingBottom:8, marginBottom:20 }}>
          {ACHIEVEMENTS.map((a, i) => {
            const unlocked = i === 0 ? (user?.streak || 0) >= 3
              : i === 1 ? (user?.total_workouts || 0) >= 10
              : i === 3 ? true : false
            return (
              <div key={a.name} style={{ flexShrink:0, width:88, background:'var(--s1)', border:`1px solid ${unlocked ? 'rgba(232,255,71,0.3)' : 'var(--border)'}`,
                borderRadius:16, padding:'14px 10px', textAlign:'center', opacity: unlocked ? 1 : 0.5 }}>
                <div style={{ fontSize:26, marginBottom:6 }}>{unlocked ? a.icon : '🔒'}</div>
                <div style={{ fontSize:10, color: unlocked ? 'var(--accent)' : 'var(--muted2)', lineHeight:1.4, fontWeight: unlocked ? 500 : 400 }}>{a.name}</div>
                {unlocked && <div style={{ fontSize:9, color:'var(--accent2)', marginTop:4 }}>+{a.xp} XP</div>}
              </div>
            )
          })}
        </div>

        {/* Workout History */}
        <div style={{ fontSize:14, fontWeight:600, marginBottom:12 }}>Workout History</div>
        {workouts.length === 0 ? (
          <div style={{ textAlign:'center', padding:'24px', color:'var(--muted2)', fontSize:13 }}>No workouts yet. Generate your first one! 💪</div>
        ) : (
          workouts.map((w: any) => (
            <div key={w.id} style={{ display:'flex', alignItems:'center', gap:12, padding:'14px 16px', background:'var(--s1)', border:'1px solid var(--border)', borderRadius:14, marginBottom:8 }}>
              <div style={{ width:36, height:36, borderRadius:10, background: w.completed ? 'rgba(71,255,184,0.1)' : 'var(--s2)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:18 }}>
                {w.completed ? '✅' : '⏳'}
              </div>
              <div style={{ flex:1 }}>
                <div style={{ fontWeight:500, fontSize:14 }}>{w.title}</div>
                <div style={{ fontSize:12, color:'var(--muted2)', marginTop:2 }}>{w.muscle_group} · {w.duration_min} min{w.kcal_burned ? ` · ${w.kcal_burned} kcal` : ''}</div>
              </div>
              <div style={{ fontSize:11, color:'var(--muted)' }}>{new Date(w.created_at).toLocaleDateString('en-IN',{day:'numeric',month:'short'})}</div>
            </div>
          ))
        )}
      </div>
    </DashLayout>
  )
}
