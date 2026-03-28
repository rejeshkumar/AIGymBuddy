'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import toast from 'react-hot-toast'
import { updateProfile, saveVitals } from '@/lib/api'
import { useStore } from '@/lib/store'

const GOALS = ['💪 Build Muscle','🔥 Burn Fat','🏃 Improve Endurance','🧘 General Fitness','🏋️ Powerlifting']
const LEVELS = ['Beginner (0–1 year)','Intermediate (1–3 years)','Advanced (3+ years)']
const STEPS = ['About You','Your Goal','Health Baseline','Ready']

export default function OnboardPage() {
  const router = useRouter()
  const { updateUser } = useStore()
  const [step, setStep] = useState(0)
  const [loading, setLoading] = useState(false)
  const [profile, setProfile] = useState({ name:'', age:'', gender:'Male', height_cm:'', weight_kg:'', goal:'💪 Build Muscle', level:'Intermediate (1–3 years)', gym_name:'', trainer_name:'' })
  const [vitals, setVitals] = useState({ blood_pressure:'', resting_hr:'', blood_glucose:'', vo2_max:'', body_fat_pct:'' })

  const sp = (k: string, v: string) => setProfile(p => ({ ...p, [k]: v }))
  const sv = (k: string, v: string) => setVitals(p => ({ ...p, [k]: v }))

  async function finish() {
    setLoading(true)
    try {
      const profileData = {
        age: profile.age ? parseInt(profile.age) : undefined,
        gender: profile.gender,
        height_cm: profile.height_cm ? parseFloat(profile.height_cm) : undefined,
        weight_kg: profile.weight_kg ? parseFloat(profile.weight_kg) : undefined,
        goal: profile.goal.replace(/^[^ ]+ /, ''),
        level: profile.level.split(' ')[0],
        gym_name: profile.gym_name || undefined,
        trainer_name: profile.trainer_name || undefined,
      }
      await updateProfile(profileData)
      updateUser(profileData)

      const vitalsData: any = {}
      if (vitals.blood_pressure) vitalsData.blood_pressure = vitals.blood_pressure
      if (vitals.resting_hr)     vitalsData.resting_hr = parseFloat(vitals.resting_hr)
      if (vitals.blood_glucose)  vitalsData.blood_glucose = parseFloat(vitals.blood_glucose)
      if (vitals.vo2_max)        vitalsData.vo2_max = parseFloat(vitals.vo2_max)
      if (vitals.body_fat_pct)   vitalsData.body_fat_pct = parseFloat(vitals.body_fat_pct)
      if (Object.keys(vitalsData).length > 0) await saveVitals(vitalsData)

      toast.success('Profile set up! Welcome to FORGE ⚡')
      router.push('/dashboard')
    } catch { toast.error('Could not save profile') }
    finally { setLoading(false) }
  }

  const Label = ({ children }: any) => (
    <label style={{ display:'block', fontSize:12, color:'var(--muted2)', letterSpacing:1, textTransform:'uppercase', marginBottom:8 }}>{children}</label>
  )

  return (
    <div style={{ minHeight:'100vh', background:'var(--bg)', display:'flex', flexDirection:'column', alignItems:'center', padding:'24px', paddingTop:48 }}>
      <div style={{ width:'100%', maxWidth:480 }}>
        {/* Progress */}
        <div style={{ display:'flex', gap:6, marginBottom:36 }}>
          {STEPS.map((_, i) => (
            <div key={i} style={{ flex:1, height:3, borderRadius:10, background: i <= step ? 'var(--accent)' : 'var(--s3)', transition:'background 0.3s' }}/>
          ))}
        </div>

        <div className="font-syne" style={{ fontSize:28, fontWeight:800, marginBottom:8 }}>{
          ['Tell us about you','What is your goal?','Health baseline','You\'re ready to FORGE'][step]
        }</div>
        <div style={{ color:'var(--muted2)', fontSize:14, marginBottom:32, lineHeight:1.6 }}>{
          ['100% personalised plan — no generic templates.',
           'Your entire training plan is built around this.',
           'Optional but powerful — AI uses this to keep you safe and maximise results.',
           'Your AI coach has your plan ready.'][step]
        }</div>

        {/* STEP 0 */}
        {step === 0 && (
          <div style={{ display:'flex', flexDirection:'column', gap:16 }}>
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:12 }}>
              <div>
                <Label>Age</Label>
                <input className="forge-input" type="number" placeholder="28" value={profile.age} onChange={e => sp('age', e.target.value)}/>
              </div>
              <div>
                <Label>Gender</Label>
                <select className="forge-input forge-select" value={profile.gender} onChange={e => sp('gender', e.target.value)}>
                  {['Male','Female','Other'].map(g => <option key={g}>{g}</option>)}
                </select>
              </div>
            </div>
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:12 }}>
              <div>
                <Label>Height (cm)</Label>
                <input className="forge-input" type="number" placeholder="175" value={profile.height_cm} onChange={e => sp('height_cm', e.target.value)}/>
              </div>
              <div>
                <Label>Weight (kg)</Label>
                <input className="forge-input" type="number" placeholder="72" value={profile.weight_kg} onChange={e => sp('weight_kg', e.target.value)}/>
              </div>
            </div>
            <div>
              <Label>Gym Name (optional)</Label>
              <input className="forge-input" placeholder="e.g. FitZone Bengaluru" value={profile.gym_name} onChange={e => sp('gym_name', e.target.value)}/>
            </div>
            <div>
              <Label>Trainer Name (optional)</Label>
              <input className="forge-input" placeholder="e.g. Coach Arjun" value={profile.trainer_name} onChange={e => sp('trainer_name', e.target.value)}/>
            </div>
          </div>
        )}

        {/* STEP 1 */}
        {step === 1 && (
          <div style={{ display:'flex', flexDirection:'column', gap:12 }}>
            {GOALS.map(g => (
              <div key={g} onClick={() => sp('goal', g)}
                style={{ padding:'16px 20px', borderRadius:14, border:`1px solid ${profile.goal===g ? 'var(--accent)' : 'var(--border2)'}`,
                  background: profile.goal===g ? 'rgba(232,255,71,0.06)' : 'var(--s2)', cursor:'pointer', transition:'all 0.2s',
                  fontWeight: profile.goal===g ? 500 : 400, fontSize:15 }}>
                {g}
              </div>
            ))}
            <div style={{ marginTop:8 }}>
              <Label>Experience Level</Label>
              <select className="forge-input forge-select" value={profile.level} onChange={e => sp('level', e.target.value)}>
                {LEVELS.map(l => <option key={l}>{l}</option>)}
              </select>
            </div>
          </div>
        )}

        {/* STEP 2 */}
        {step === 2 && (
          <div style={{ display:'flex', flexDirection:'column', gap:16 }}>
            <div style={{ padding:'14px 16px', background:'rgba(71,255,184,0.06)', border:'1px solid rgba(71,255,184,0.2)', borderRadius:12, fontSize:13, color:'var(--muted2)', lineHeight:1.6 }}>
              🩺 Visit your gym doctor or clinic and get these tested. Upload or enter results here — AI analyses them instantly.
            </div>
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:12 }}>
              {[
                { k:'blood_pressure', label:'Blood Pressure', placeholder:'120/80' },
                { k:'resting_hr',     label:'Resting HR (bpm)', placeholder:'65' },
                { k:'blood_glucose',  label:'Blood Glucose (mg/dL)', placeholder:'95' },
                { k:'vo2_max',        label:'VO2 Max (optional)', placeholder:'46' },
                { k:'body_fat_pct',   label:'Body Fat % (optional)', placeholder:'18' },
              ].map(f => (
                <div key={f.k}>
                  <Label>{f.label}</Label>
                  <input className="forge-input" placeholder={f.placeholder} value={(vitals as any)[f.k]} onChange={e => sv(f.k, e.target.value)}/>
                </div>
              ))}
            </div>
            <div style={{ fontSize:12, color:'var(--muted)', textAlign:'center' }}>All health data is encrypted and private.</div>
          </div>
        )}

        {/* STEP 3 */}
        {step === 3 && (
          <div style={{ display:'flex', flexDirection:'column', gap:12 }}>
            {[
              { icon:'⚡', label:'AI Workout Plan', value:`${profile.goal.replace(/^[^ ]+ /,'')} · ${profile.level.split(' ')[0]}` },
              { icon:'🤖', label:'AI Coach', value:'Online and ready' },
              { icon:'🩺', label:'Health Monitoring', value: Object.values(vitals).some(Boolean) ? 'Vitals loaded' : 'Add vitals anytime' },
              { icon:'📊', label:'Progress Tracking', value:'Starts today' },
            ].map(item => (
              <div key={item.label} style={{ display:'flex', alignItems:'center', gap:14, padding:'14px 16px', background:'var(--s2)', borderRadius:12, border:'1px solid var(--border)' }}>
                <span style={{ fontSize:24 }}>{item.icon}</span>
                <div style={{ flex:1 }}>
                  <div style={{ fontWeight:500, fontSize:14 }}>{item.label}</div>
                  <div style={{ fontSize:12, color:'var(--muted2)', marginTop:2 }}>{item.value}</div>
                </div>
                <div style={{ width:8, height:8, borderRadius:'50%', background:'var(--accent2)' }}/>
              </div>
            ))}
          </div>
        )}

        {/* Navigation */}
        <div style={{ display:'flex', gap:12, marginTop:32 }}>
          {step > 0 && (
            <button className="btn-ghost" onClick={() => setStep(s => s-1)} style={{ flex:1, padding:'14px', fontSize:15 }}>← Back</button>
          )}
          {step < 3
            ? <button className="btn-primary" onClick={() => setStep(s => s+1)} style={{ flex:2, padding:'14px', fontSize:15 }}>Continue →</button>
            : <button className="btn-primary" onClick={finish} disabled={loading} style={{ flex:2, padding:'14px', fontSize:15 }}>
                {loading ? <span className="spinner"/> : 'Enter FORGE ⚡'}
              </button>
          }
        </div>
        {step < 3 && (
          <div onClick={() => router.push('/dashboard')} style={{ textAlign:'center', marginTop:16, fontSize:13, color:'var(--muted)', cursor:'pointer' }}>
            Skip for now
          </div>
        )}
      </div>
    </div>
  )
}
