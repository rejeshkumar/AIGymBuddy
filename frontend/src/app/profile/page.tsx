'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import toast from 'react-hot-toast'
import DashLayout from '../dashboard/layout'
import { useStore } from '@/lib/store'
import { updateProfile } from '@/lib/api'

export default function ProfilePage() {
  const { user, updateUser, logout } = useStore()
  const router = useRouter()
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState({
    name: user?.name || '', age: user?.age?.toString() || '',
    gender: user?.gender || 'Male', height_cm: user?.height_cm?.toString() || '',
    weight_kg: user?.weight_kg?.toString() || '', goal: user?.goal || 'Build Muscle',
    level: user?.level || 'Intermediate', gym_name: user?.gym_name || '', trainer_name: user?.trainer_name || ''
  })
  const sf = (k: string, v: string) => setForm(f => ({ ...f, [k]: v }))

  async function save() {
    setSaving(true)
    try {
      const data = { ...form, age: form.age ? parseInt(form.age) : undefined, height_cm: form.height_cm ? parseFloat(form.height_cm) : undefined, weight_kg: form.weight_kg ? parseFloat(form.weight_kg) : undefined }
      await updateProfile(data)
      updateUser(data as any)
      toast.success('Profile saved ✓')
    } catch { toast.error('Could not save profile') }
    finally { setSaving(false) }
  }

  function handleLogout() {
    logout()
    router.push('/login')
    toast.success('Signed out')
  }

  const initials = user?.name?.split(' ').map((w: string) => w[0]).join('').toUpperCase().slice(0,2) || 'U'

  return (
    <DashLayout>
      <div style={{ padding:'20px' }}>
        {/* Profile Hero */}
        <div style={{ display:'flex', alignItems:'center', gap:16, marginBottom:28 }}>
          <div style={{ width:72, height:72, borderRadius:24, background:'linear-gradient(135deg, var(--accent), var(--accent2))', display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'Syne,sans-serif', fontSize:24, fontWeight:800, color:'#060608', flexShrink:0 }}>{initials}</div>
          <div>
            <div className="font-syne" style={{ fontSize:20, fontWeight:800 }}>{user?.name}</div>
            <div style={{ fontSize:13, color:'var(--muted2)', marginTop:2 }}>{user?.level} · {user?.goal}</div>
            <div style={{ display:'flex', gap:6, marginTop:8, flexWrap:'wrap' }}>
              <span className="chip chip-yellow">🔥 {user?.streak} Streak</span>
              <span className="chip chip-green">⚡ {user?.xp?.toLocaleString()} XP</span>
              <span className="chip chip-orange">💪 {user?.total_workouts} Workouts</span>
            </div>
          </div>
        </div>

        {/* Form */}
        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:12, marginBottom:16 }}>
          {[
            { k:'name', label:'Full Name', ph:'Rejesh Kumar', span:2 },
            { k:'age', label:'Age', ph:'28', type:'number' },
            { k:'gender', label:'Gender', type:'select', opts:['Male','Female','Other'] },
            { k:'height_cm', label:'Height (cm)', ph:'175', type:'number' },
            { k:'weight_kg', label:'Weight (kg)', ph:'72', type:'number' },
            { k:'goal', label:'Goal', type:'select', opts:['Build Muscle','Burn Fat','Improve Endurance','General Fitness','Powerlifting'] },
            { k:'level', label:'Level', type:'select', opts:['Beginner','Intermediate','Advanced'] },
            { k:'gym_name', label:'Gym Name', ph:'FitZone Bengaluru', span:2 },
            { k:'trainer_name', label:'Trainer Name', ph:'Coach Arjun', span:2 },
          ].map((f: any) => (
            <div key={f.k} style={{ gridColumn: f.span === 2 ? 'span 2' : 'span 1' }}>
              <div style={{ fontSize:11, textTransform:'uppercase', letterSpacing:1, color:'var(--muted2)', marginBottom:8 }}>{f.label}</div>
              {f.type === 'select'
                ? <select className="forge-input forge-select" value={(form as any)[f.k]} onChange={e => sf(f.k, e.target.value)}>
                    {f.opts.map((o: string) => <option key={o}>{o}</option>)}
                  </select>
                : <input className="forge-input" type={f.type || 'text'} placeholder={f.ph} value={(form as any)[f.k]} onChange={e => sf(f.k, e.target.value)}/>
              }
            </div>
          ))}
        </div>

        <button className="btn-primary" onClick={save} disabled={saving} style={{ width:'100%', padding:'15px', fontSize:15, marginBottom:12 }}>
          {saving ? <span className="spinner"/> : 'Save Profile'}
        </button>

        <button onClick={handleLogout}
          style={{ width:'100%', padding:'14px', fontSize:14, borderRadius:50, border:'1px solid rgba(255,71,87,0.3)', background:'rgba(255,71,87,0.08)', color:'var(--danger)', cursor:'pointer', fontFamily:'DM Sans,sans-serif', fontWeight:500 }}>
          Sign Out
        </button>

        <div style={{ textAlign:'center', marginTop:24, fontSize:11, color:'var(--muted)', lineHeight:1.6 }}>
          FORGE v1.0 · Built with AI · Your data is encrypted and private.
        </div>
      </div>
    </DashLayout>
  )
}
