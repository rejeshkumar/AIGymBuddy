import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface User {
  id: string
  email: string
  name: string
  goal?: string
  level?: string
  streak: number
  xp: number
  total_workouts: number
  weight_kg?: number
  height_cm?: number
  age?: number
  gender?: string
  gym_name?: string
  trainer_name?: string
}

interface AppStore {
  token: string | null
  user: User | null
  setAuth: (token: string, user: User) => void
  updateUser: (updates: Partial<User>) => void
  logout: () => void
}

export const useStore = create<AppStore>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      setAuth: (token, user) => set({ token, user }),
      updateUser: (updates) => set((s) => ({ user: s.user ? { ...s.user, ...updates } : null })),
      logout: () => set({ token: null, user: null }),
    }),
    { name: 'forge-store' }
  )
)
