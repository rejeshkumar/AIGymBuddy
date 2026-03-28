import axios from 'axios'

const BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

const api = axios.create({ baseURL: BASE })

api.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const raw = localStorage.getItem('forge-store')
    if (raw) {
      try {
        const { state } = JSON.parse(raw)
        if (state?.token) config.headers.Authorization = `Bearer ${state.token}`
      } catch {}
    }
  }
  return config
})

export default api

// Auth
export const register = (email: string, password: string, name: string) =>
  api.post('/api/auth/register', { email, password, name })

export const login = (email: string, password: string) =>
  api.post('/api/auth/login', { email, password })

// Users
export const getProfile = () => api.get('/api/users/me')
export const updateProfile = (data: any) => api.patch('/api/users/me', data)
export const logWeight = (weight_kg: number, note?: string) =>
  api.post('/api/users/weight', { weight_kg, note })
export const getWeightHistory = () => api.get('/api/users/weight/history')

// Workouts
export const generateWorkout = (params: any) =>
  api.post('/api/workouts/generate', params)
export const completeWorkout = (workout_id: string, kcal_burned?: number) =>
  api.post('/api/workouts/complete', { workout_id, kcal_burned })
export const getWorkoutHistory = () => api.get('/api/workouts/history')

// Health
export const saveVitals = (data: any) => api.post('/api/health/vitals', data)
export const analyseReport = (report_text: string) =>
  api.post('/api/health/report/analyse', { report_text })
export const getLatestHealth = () => api.get('/api/health/latest')

// Coach
export const chatWithCoach = (message: string, history: any[]) =>
  api.post('/api/coach/chat', { message, history })
export const getDailyInsight = () => api.get('/api/coach/daily-insight')
export const getFormFeedback = (exercise: string, rep_count: number) =>
  api.post('/api/coach/form-feedback', { exercise, rep_count })
