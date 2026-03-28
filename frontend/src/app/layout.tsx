import type { Metadata } from 'next'
import { Toaster } from 'react-hot-toast'
import './globals.css'

export const metadata: Metadata = {
  title: 'FORGE — Your AI Fitness OS',
  description: 'Medical-grade health insights. Real-time AI coaching. Built for serious gym-goers.',
  viewport: 'width=device-width, initial-scale=1, maximum-scale=1',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;700;800&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet"/>
      </head>
      <body>
        {children}
        <Toaster
          position="top-center"
          toastOptions={{
            style: {
              background: '#16161c',
              color: '#f4f4f8',
              border: '1px solid rgba(255,255,255,0.13)',
              fontFamily: 'DM Sans, sans-serif',
              fontSize: '13px',
            },
            success: { iconTheme: { primary: '#47ffb8', secondary: '#060608' } },
            error:   { iconTheme: { primary: '#ff4757', secondary: '#fff' } },
          }}
        />
      </body>
    </html>
  )
}
