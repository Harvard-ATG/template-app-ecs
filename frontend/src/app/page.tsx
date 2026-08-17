'use client';

import { useAuth } from '@/hooks/useAuth';
import { Dashboard } from '@/components/dashboard/Dashboard';
import { AuthButton } from '@/components/auth/AuthButton';
import { Navbar } from '@/components/layout/Navbar';
import { Container } from '@/components/layout/Container';

export default function Home() {
  const { user } = useAuth();
  
  if (user) {
    return <Dashboard />;
  }
  
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      <Navbar />
      
      <main className="flex items-center justify-center py-20">
        <Container maxWidth="2xl">
          <div className="text-center">
            {/* Hero Section */}
            <div className="mb-12">
              <h1 className="text-5xl md:text-6xl font-extrabold text-gray-900 mb-6 leading-tight">
                Welcome to <span className="text-blue-600">My App</span>
              </h1>
              <p className="text-xl md:text-2xl text-gray-600 mb-4">
                Full-stack application with authentication and AI capabilities
              </p>
              <p className="text-base text-gray-500">
                Built with FastAPI, Next.js, PostgreSQL, and Claude AI
              </p>
            </div>
            
            {/* Features Grid */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
              <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
                <div className="text-blue-600 text-4xl mb-3">🔐</div>
                <h3 className="font-semibold text-lg text-gray-900 mb-2">Secure Authentication</h3>
                <p className="text-sm text-gray-600">
                  Password hashing with Argon2 and session-based auth
                </p>
              </div>
              
              <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
                <div className="text-blue-600 text-4xl mb-3">🤖</div>
                <h3 className="font-semibold text-lg text-gray-900 mb-2">AI Playground</h3>
                <p className="text-sm text-gray-600">
                  Interact with Claude AI for intelligent conversations
                </p>
              </div>
              
              <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
                <div className="text-blue-600 text-4xl mb-3">📊</div>
                <h3 className="font-semibold text-lg text-gray-900 mb-2">User Dashboard</h3>
                <p className="text-sm text-gray-600">
                  Track your sessions, profile, and activity
                </p>
              </div>
            </div>
            
            {/* CTA Button */}
            <AuthButton />
            
            {/* Tech Stack */}
            <div className="mt-16 pt-8 border-t border-gray-200">
              <p className="text-sm text-gray-500 mb-4">Built with modern technologies</p>
              <div className="flex flex-wrap justify-center gap-4 text-sm text-gray-600">
                <span className="px-3 py-1 bg-white rounded-full border border-gray-200">FastAPI</span>
                <span className="px-3 py-1 bg-white rounded-full border border-gray-200">Next.js 15</span>
                <span className="px-3 py-1 bg-white rounded-full border border-gray-200">TypeScript</span>
                <span className="px-3 py-1 bg-white rounded-full border border-gray-200">PostgreSQL</span>
                <span className="px-3 py-1 bg-white rounded-full border border-gray-200">Tailwind CSS</span>
                <span className="px-3 py-1 bg-white rounded-full border border-gray-200">Docker</span>
              </div>
            </div>
          </div>
        </Container>
      </main>
    </div>
  );
}
