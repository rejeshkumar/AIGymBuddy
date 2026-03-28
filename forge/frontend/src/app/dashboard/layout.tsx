'use client'
import { useEffect } from 'react'
import { useRouter, usePathname } from 'next/navigation'
import Link from 'next/link'
import { useStore } from '@/lib/store'

const NAV = [
  { href:'/dashboard', label:'Home',     icon:'⚡' },
  { href:'/workout',   label:'Workout',  icon:'💪' },
  { href:'/coach',     label:'Coach',    icon:'🤖' },
  { href:'/health',    label:'Health',   icon:'❤️' },
  { href:'/progress',  label:'Progress', icon:'📊' },
  { href:'/profile',   label:'Profile',  icon:'👤' },
]

export default function DashLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter()
  const pathname = usePathname()
  const token = useStore((s) => s.token)

  useEffect(() => {
    if (!token) router.replace('/login')
  }, [token, router])

  if (!token) return null

  return (
    <div style={{ display:'flex', flexDirection:'column', minHeight:'100vh', maxWidth:520, margin:'0 auto', background:'var(--bg)', position:'relative' }}>
      <main style={{ flex:1, paddingBottom:80, overflowX:'hidden' }}>
        {children}
      </main>
      <nav style={{ position:'fixed', bottom:0, left:'50%', transform:'translateX(-50%)', width:'100%', maxWidth:520, background:'rgba(6,6,8,0.96)', backdropFilter:'blur(20px)', borderTop:'1px solid var(--border)', display:'flex', zIndex:100 }}>
        {NAV.map(n => {
          const active = pathname === n.href
          return (
            <Link key={n.href} href={n.href} style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:'10px 0', gap:3, textDecoration:'none',
              color: active ? 'var(--accent)' : 'var(--muted)', transition:'color 0.2s' }}>
              <span style={{ fontSize:18, filter: active ? 'drop-shadow(0 0 6px var(--accent))' : 'none', transition:'filter 0.2s' }}>{n.icon}</span>
              <span style={{ fontSize:9, letterSpacing:'0.5px', textTransform:'uppercase', fontWeight: active ? 600 : 400 }}>{n.label}</span>
            </Link>
          )
        })}
      </nav>
    </div>
  )
}
