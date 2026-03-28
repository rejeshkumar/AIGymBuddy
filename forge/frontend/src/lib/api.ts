import axios from "axios";
const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";
const api = axios.create({ baseURL: API_URL });
api.interceptors.request.use((config) => {
  if (typeof window !== "undefined") {
    const token = localStorage.getItem("forge_token");
    if (token) config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
api.interceptors.response.use((res) => res, (err) => {
  if (err.response?.status === 401 && typeof window !== "undefined") {
    localStorage.removeItem("forge_token");
    window.location.href = "/login";
  }
  return Promise.reject(err);
});
export const authAPI = {
  register: (d: any) => api.post("/api/auth/register", d),
  login: (d: any) => api.post("/api/auth/login", d),
};
export const usersAPI = {
  getMe: () => api.get("/api/users/me"),
  updateProfile: (d: any) => api.patch("/api/users/me", d),
  logWeight: (weight_kg: number, note?: string) => api.post("/api/users/weight", { weight_kg, note }),
  getWeightHistory: () => api.get("/api/users/weight/history"),
};
export const workoutsAPI = {
  generate: (d: any) => api.post("/api/workouts/generate", d),
  complete: (workout_id: string, kcal?: number) => api.post("/api/workouts/complete", { workout_id, kcal_burned: kcal }),
  getHistory: () => api.get("/api/workouts/history"),
};
export const healthAPI = {
  saveVitals: (d: any) => api.post("/api/health/vitals", d),
  analyseReport: (report_text: string) => api.post("/api/health/report/analyse", { report_text }),
  getLatest: () => api.get("/api/health/latest"),
};
export const coachAPI = {
  chat: (message: string, history: any[]) => api.post("/api/coach/chat", { message, history }),
  getDailyInsight: () => api.get("/api/coach/daily-insight"),
};
export default api;
