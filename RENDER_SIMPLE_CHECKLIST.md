# Render Deployment – Simple Checklist

**Tick each box as you complete it. If you get stuck, tell me the number of the step.**

---

## A. Do you have a PostgreSQL database?

- [ ] **A1.** I went to Render dashboard → clicked **+ New** → clicked **PostgreSQL**
- [ ] **A2.** I filled in a name (e.g. `aigymbuddy-db`) and clicked **Create Database**
- [ ] **A3.** I waited until it said **Available**
- [ ] **A4.** I clicked on the database and copied the **Internal Database URL**

**If you haven't done A yet:** Start with Step A1. You need a database before the app can work.

---

## B. Add the database URL to your app

- [ ] **B1.** I clicked on my **AIGymBuddy** web service (not the database)
- [ ] **B2.** I clicked **Environment** in the left menu
- [ ] **B3.** I clicked **Add Environment Variable** (or **Add Variable**)
- [ ] **B4.** I typed `DATABASE_URL` in the Key/Name box
- [ ] **B5.** I pasted the database URL in the Value box
- [ ] **B6.** I clicked **Save** or **Add**

---

## C. Add the other two variables

- [ ] **C1.** I clicked **Add Environment Variable** again
- [ ] **C2.** Key: `SECRET_KEY` | Value: `my-secret-key-12345` (or any random text)
- [ ] **C3.** I clicked **Add Environment Variable** again
- [ ] **C4.** Key: `CORS_ORIGINS` | Value: `*`

---

## D. Redeploy

- [ ] **D1.** I clicked **Manual Deploy** (top right of the page)
- [ ] **D2.** I waited 3–5 minutes for the build to finish
- [ ] **D3.** The status turned green / **Live**

---

## E. Test it

- [ ] **E1.** I clicked my app URL (e.g. `https://aigymbuddy.onrender.com`)
- [ ] **E2.** I saw something like `{"status":"ok","app":"AI GYM Buddy"}`

---

# Where are you stuck?

**Reply with one of these:**

1. "I don't have a database" → I'll guide you through creating one
2. "I can't find Environment" → I'll describe exactly where to click
3. "I don't have the database URL" → I'll show you where to get it
4. "I added everything but it's still failing" → Share the error from the Logs tab
5. "Something else" → Describe what you see on the screen
