'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import toast from 'react-hot-toast'
import { login, register } from '@/lib/api'
import { useStore } from '@/lib/store'

export default function LoginPage() {
  const router = useRouter()
  const setAuth = useStore((s) => s.setAuth)
  const [mode, setMode] = useState<'login' | 'register'>('login')
  const [loading, setLoading] = useState(false)
  const [form, setForm] = useState({ email: '', password: '', name: '' })

  const set = (k: string, v: string) => setForm(f => ({ ...f, [k]: v }))

  async function submit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    try {
      const res = mode === 'login'
        ? await login(form.email, form.password)
        : await register(form.email, form.password, form.name)
      setAuth(res.data.token, res.data.user)
      toast.success(mode === 'login' ? `Welcome back, ${res.data.user.name}!` : `Welcome to FORGE, ${res.data.user.name}!`)
      router.push(mode === 'register' ? '/onboard' : '/dashboard')
    } catch (err: any) {
      toast.error(err?.response?.data?.detail || 'Something went wrong')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ minHeight:'100vh', background:'var(--bg)', display:'flex', alignItems:'center', justifyContent:'center', padding:'24px' }}>
      <div style={{ width:'100%', maxWidth:420 }}>
        {/* Logo */}
        <div className="fade-up" style={{ textAlign:'center', marginBottom:40 }}>
          <div className="font-syne" style={{ fontSize:48, fontWeight:800, color:'var(--accent)', letterSpacing:4, lineHeight:1 }}>FORGE</div>
          <div style={{ color:'var(--muted2)', marginTop:8, fontSize:14 }}>Your AI Fitness OS</div>
        </div>

        {/* Card */}
        <div className="card fade-up-1" style={{ borderRadius:24 }}>
          {/* Tabs */}
          <div style={{ display:'flex', background:'var(--s2)', borderRadius:12, padding:4, marginBottom:28 }}>
            {(['login','register'] as const).map(m => (
              <button key={m} onClick={() => setMode(m)}
                style={{ flex:1, padding:'10px', borderRadius:10, border:'none', cursor:'pointer', fontFamily:'DM Sans,sans-serif', fontWeight:500, fontSize:14, transition:'all 0.2s',
                  background: mode===m ? 'var(--accent)' : 'transparent',
                  color: mode===m ? '#060608' : 'var(--muted2)',
                }}>
                {m === 'login' ? 'Sign In' : 'Create Account'}
              </button>
            ))}
          </div>

          <form onSubmit={submit}>
            {mode === 'register' && (
              <div style={{ marginBottom:16 }}>
                <label style={{ display:'block', fontSize:12, color:'var(--muted2)', letterSpacing:1, textTransform:'uppercase', marginBottom:8 }}>Full Name</label>
                <input className="forge-input" placeholder="Rejesh Kumar" value={form.name} onChange={e => set('name', e.target.value)} required/>
              </div>
            )}
            <div style={{ marginBottom:16 }}>
              <label style={{ display:'block', fontSize:12, color:'var(--muted2)', letterSpacing:1, textTransform:'uppercase', marginBottom:8 }}>Email</label>
              <input className="forge-input" type="email" placeholder="you@example.com" value={form.email} onChange={e => set('email', e.target.value)} required/>
            </div>
            <div style={{ marginBottom:28 }}>
              <label style={{ display:'block', fontSize:12, color:'var(--muted2)', letterSpacing:1, textTransform:'uppercase', marginBottom:8 }}>Password</label>
              <input className="forge-input" type="password" placeholder="••••••••" value={form.password} onChange={e => set('password', e.target.value)} required minLength={6}/>
            </div>
            <button className="btn-primary" type="submit" disabled={loading}
              style={{ width:'100%', padding:'16px', fontSize:16 }}>
              {loading ? <span className="spinner"/> : mode === 'login' ? 'Sign In ⚡' : 'Create Account →'}
            </button>
          </form>
        </div>

        <div className="fade-up-2" style={{ textAlign:'center', marginTop:24, fontSize:13, color:'var(--muted)' }}>
          Built for people who are serious about results.
        </div>
      </div>
    </div>
  )
}
