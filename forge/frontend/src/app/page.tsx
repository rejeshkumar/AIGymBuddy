'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useStore } from '@/lib/store'

export default function RootPage() {
  const router = useRouter()
  const token = useStore((s) => s.token)
  useEffect(() => {
    router.replace(token ? '/dashboard' : '/login')
  }, [token, router])
  return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center', height:'100vh', background:'var(--bg)' }}>
      <div className="spinner" style={{ width:32, height:32 }}/>
    </div>
  )
}
