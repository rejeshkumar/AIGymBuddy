'use client'
import { useState, useEffect } from 'react'
import toast from 'react-hot-toast'
import DashLayout from '../dashboard/layout'
import { saveVitals, analyseReport, getLatestHealth } from '@/lib/api'

export default function HealthPage() {
  const [health, setHealth] = useState<any>(null)
  const [vitals, setVitals] = useState({ blood_pressure:'', resting_hr:'', blood_glucose:'', vo2_max:'', cholesterol:'', body_fat_pct:'', vitamin_d:'', hemoglobin:'' })
  const [reportText, setReportText] = useState('')
  const [tab, setTab] = useState<'overview'|'vitals'|'report'>('overview')
  const [saving, setSaving] = useState(false)
  const [analysing, setAnalysing] = useState(false)
  const [insights, setInsights] = useState<any[]>([])

  useEffect(() => {
    getLatestHealth().then(r => {
      if (!r.data.message) {
        setHealth(r.data)
        setInsights(r.data.insights || [])
      }
    }).catch(() => {})
  }, [])

  async function handleSaveVitals() {
    setSaving(true)
    const data: any = {}
    Object.entries(vitals).forEach(([k,v]) => { if(v) data[k] = k === 'blood_pressure' ? v : parseFloat(v) })
    if (!Object.keys(data).length) { toast.error('Enter at least one vital'); setSaving(false); return }
    try {
      const r = await saveVitals(data)
      setHealth({ ...data })
      setInsights(r.data.insights || [])
      toast.success('Vitals saved and analysed by AI ✓')
      setTab('overview')
    } catch { toast.error('Could not save vitals') }
    finally { setSaving(false) }
  }

  async function handleAnalyseReport() {
    if (!reportText.trim()) { toast.error('Paste your report text first'); return }
    setAnalysing(true)
    try {
      const r = await analyseReport(reportText)
      setInsights(r.data.insights || [])
      if (r.data.extracted) setHealth(r.data.extracted)
      toast.success('Report analysed by AI ✓')
      setTab('overview')
    } catch { toast.error('Could not analyse report') }
    finally { setAnalysing(false) }
  }

  const sv = (k: string, v: string) => setVitals(p => ({ ...p, [k]: v }))

  const VitalCard = ({ icon, label, value, unit, status }: any) => (
    <div style={{ background:'var(--s1)', border:'1px solid var(--border)', borderRadius:16, padding:16, cursor:'pointer' }}>
      <div style={{ width:36, height:36, borderRadius:10, background:'var(--s2)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:18, marginBottom:10 }}>{icon}</div>
      <div className="font-syne" style={{ fontSize:22, fontWeight:800, lineHeight:1 }}>{value || '—'}<span style={{ fontSize:13, fontWeight:400, color:'var(--muted2)', marginLeft:3 }}>{value ? unit : ''}</span></div>
      <div style={{ fontSize:11, color:'var(--muted2)', marginTop:4 }}>{label}</div>
      {status && <div style={{ fontSize:10, marginTop:6, fontWeight:600, color: status==='good' ? 'var(--accent2)' : status==='warn' ? 'var(--accent3)' : 'var(--danger)' }}>● {status==='good' ? 'Optimal' : status==='warn' ? 'Watch' : 'Alert'}</div>}
    </div>
  )

  return (
    <DashLayout>
      <div style={{ padding:'20px 20px 0' }}>
        <div style={{ fontSize:11, textTransform:'uppercase', letterSpacing:1, color:'var(--muted2)' }}>Medical-Grade</div>
        <div className="font-syne fade-up" style={{ fontSize:28, fontWeight:800, marginBottom:20 }}>Your Health</div>

        {/* Tabs */}
        <div style={{ display:'flex', background:'var(--s2)', borderRadius:12, padding:4, marginBottom:20 }}>
          {(['overview','vitals','report'] as const).map(t => (
            <button key={t} onClick={() => setTab(t)}
              style={{ flex:1, padding:'9px', borderRadius:10, border:'none', cursor:'pointer', fontFamily:'DM Sans,sans-serif', fontWeight:500, fontSize:13, transition:'all 0.2s', textTransform:'capitalize',
                background: tab===t ? 'var(--accent)' : 'transparent', color: tab===t ? '#060608' : 'var(--muted2)' }}>
              {t === 'report' ? 'AI Report' : t.charAt(0).toUpperCase()+t.slice(1)}
            </button>
          ))}
        </div>

        {/* OVERVIEW */}
        {tab === 'overview' && (
          <div>
            {!health ? (
              <div style={{ textAlign:'center', padding:'40px 20px' }}>
                <div style={{ fontSize:40, marginBottom:12 }}>🩺</div>
                <div className="font-syne" style={{ fontSize:20, fontWeight:700, marginBottom:8 }}>No health data yet</div>
                <div style={{ color:'var(--muted2)', fontSize:14, marginBottom:24 }}>Add your vitals or upload a blood report — AI will analyse them instantly.</div>
                <button className="btn-primary" onClick={() => setTab('vitals')} style={{ padding:'13px 28px', fontSize:14 }}>Add Vitals →</button>
              </div>
            ) : (
              <>
                <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:10, marginBottom:20 }}>
                  <VitalCard icon="❤️" label="Blood Pressure" value={health.blood_pressure} unit="" status="good"/>
                  <VitalCard icon="💓" label="Resting HR" value={health.resting_hr} unit="bpm" status="good"/>
                  <VitalCard icon="🩸" label="Blood Glucose" value={health.blood_glucose} unit="mg/dL" status="good"/>
                  <VitalCard icon="🫁" label="VO2 Max" value={health.vo2_max} unit="ml/kg" status="warn"/>
                  <VitalCard icon="☀️" label="Vitamin D" value={health.vitamin_d} unit="ng/mL" status={health.vitamin_d && health.vitamin_d < 30 ? 'warn' : 'good'}/>
                  <VitalCard icon="⚖️" label="Body Fat" value={health.body_fat_pct} unit="%" status="good"/>
                </div>

                {insights.length > 0 && (
                  <>
                    <div style={{ fontSize:14, fontWeight:600, marginBottom:12 }}>AI Health Insights</div>
                    {insights.map((ins: any, i: number) => (
                      <div key={i} style={{ borderLeft:`3px solid ${ins.level==='good' ? 'var(--accent2)' : ins.level==='warn' ? 'var(--accent3)' : 'var(--danger)'}`,
                        padding:'12px 14px', background:'var(--s1)', borderRadius:'0 12px 12px 0', marginBottom:10 }}>
                        <div style={{ fontSize:10, textTransform:'uppercase', letterSpacing:1.5, fontWeight:600, marginBottom:4,
                          color: ins.level==='good' ? 'var(--accent2)' : ins.level==='warn' ? 'var(--accent3)' : 'var(--danger)' }}>
                          {ins.level === 'good' ? '✓ Optimised' : ins.level === 'warn' ? '⚡ Attention' : '🚨 Alert'} · {ins.marker}
                        </div>
                        <div style={{ fontSize:13, color:'var(--muted2)', lineHeight:1.6 }}>{ins.message}</div>
                      </div>
                    ))}
                  </>
                )}
              </>
            )}
          </div>
        )}

        {/* VITALS INPUT */}
        {tab === 'vitals' && (
          <div>
            <div style={{ padding:'14px 16px', background:'rgba(71,255,184,0.06)', border:'1px solid rgba(71,255,184,0.2)', borderRadius:12, marginBottom:20, fontSize:13, color:'var(--muted2)', lineHeight:1.6 }}>
              🩺 Visit your gym clinic or doctor. Enter your results here — our AI analyses them in seconds and adjusts your training plan.
            </div>
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:12, marginBottom:20 }}>
              {[
                { k:'blood_pressure', label:'Blood Pressure', ph:'120/80' },
                { k:'resting_hr',     label:'Resting HR (bpm)', ph:'65' },
                { k:'blood_glucose',  label:'Glucose (mg/dL)', ph:'95' },
                { k:'vo2_max',        label:'VO2 Max', ph:'46' },
                { k:'cholesterol',    label:'Cholesterol (mg/dL)', ph:'180' },
                { k:'body_fat_pct',   label:'Body Fat %', ph:'18' },
                { k:'vitamin_d',      label:'Vitamin D (ng/mL)', ph:'32' },
                { k:'hemoglobin',     label:'Hemoglobin (g/dL)', ph:'14.2' },
              ].map(f => (
                <div key={f.k}>
                  <div style={{ fontSize:11, textTransform:'uppercase', letterSpacing:1, color:'var(--muted2)', marginBottom:8 }}>{f.label}</div>
                  <input className="forge-input" placeholder={f.ph} value={(vitals as any)[f.k]} onChange={e => sv(f.k, e.target.value)}/>
                </div>
              ))}
            </div>
            <button className="btn-primary" onClick={handleSaveVitals} disabled={saving} style={{ width:'100%', padding:'15px', fontSize:15 }}>
              {saving ? <span className="spinner"/> : '🧬 Save & Analyse with AI'}
            </button>
          </div>
        )}

        {/* REPORT OCR */}
        {tab === 'report' && (
          <div>
            <div style={{ padding:'14px 16px', background:'rgba(232,255,71,0.06)', border:'1px solid rgba(232,255,71,0.2)', borderRadius:12, marginBottom:16, fontSize:13, lineHeight:1.6 }}>
              📋 Copy and paste the text from your blood test or health report below. AI will extract all key markers and give you personalised insights.
            </div>
            <textarea className="forge-input" rows={12} placeholder="Paste your blood report text here...&#10;&#10;Example:&#10;Hemoglobin: 14.2 g/dL&#10;Cholesterol: 198 mg/dL&#10;Vitamin D: 18 ng/mL&#10;Blood Glucose: 96 mg/dL&#10;..."
              value={reportText} onChange={e => setReportText(e.target.value)}
              style={{ resize:'vertical', fontFamily:'DM Sans,sans-serif', marginBottom:16 }}/>
            <button className="btn-primary" onClick={handleAnalyseReport} disabled={analysing} style={{ width:'100%', padding:'15px', fontSize:15 }}>
              {analysing ? <><span className="spinner"/> Analysing with AI...</> : '🤖 Analyse Report with AI'}
            </button>
          </div>
        )}
      </div>
    </DashLayout>
  )
}
