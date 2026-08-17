'use client';

import React from 'react';
import { useAuth } from '@/hooks/useAuth';
import { UserProfile } from './UserProfile';
import { UserStats } from './UserStats';
import { LLMPlayground } from './LLMPlayground';
import { Navbar } from '@/components/layout/Navbar';
import { Container } from '@/components/layout/Container';

export function Dashboard() {
  const { user, sessionId, sessionExpiry } = useAuth();
  
  if (!user || !sessionId || !sessionExpiry) {
    return null;
  }
  
  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      
      <main className="py-8">
        <Container>
          <div className="mb-6">
            <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
            <p className="text-gray-600 mt-2">Welcome back, {user.full_name || user.email}!</p>
          </div>
          
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-1">
              <UserProfile
                user={user}
                sessionId={sessionId}
                sessionExpiry={sessionExpiry}
              />
            </div>
            
            <div className="lg:col-span-1">
              <UserStats
                user={user}
                sessionExpiry={sessionExpiry}
              />
            </div>
            
            <div className="lg:col-span-1">
              <LLMPlayground />
            </div>
          </div>
        </Container>
      </main>
    </div>
  );
}
