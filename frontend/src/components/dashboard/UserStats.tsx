'use client';

import React, { useState, useEffect } from 'react';
import { Card } from '@/components/ui/Card';
import type { User } from '@/lib/types';

interface UserStatsProps {
  user: User;
  sessionExpiry: string;
}

export function UserStats({ user, sessionExpiry }: UserStatsProps) {
  const [timeRemaining, setTimeRemaining] = useState('');
  
  useEffect(() => {
    const updateCountdown = () => {
      const now = new Date().getTime();
      const expiry = new Date(sessionExpiry).getTime();
      const diff = expiry - now;
      
      if (diff <= 0) {
        setTimeRemaining('Expired');
        return;
      }
      
      const hours = Math.floor(diff / (1000 * 60 * 60));
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((diff % (1000 * 60)) / 1000);
      
      setTimeRemaining(`${hours}h ${minutes}m ${seconds}s`);
    };
    
    updateCountdown();
    const interval = setInterval(updateCountdown, 1000);
    
    return () => clearInterval(interval);
  }, [sessionExpiry]);
  
  const getAccountAge = () => {
    const created = new Date(user.created_at).getTime();
    const now = new Date().getTime();
    const diffDays = Math.floor((now - created) / (1000 * 60 * 60 * 24));
    
    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return '1 day ago';
    return `${diffDays} days ago`;
  };
  
  return (
    <Card title="📊 Session Stats">
      <div className="space-y-4">
        <div className="p-4 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-lg border border-blue-100">
          <p className="text-xs uppercase tracking-wide text-blue-600 mb-1">Session Expires In</p>
          <p className="text-2xl font-bold text-blue-900 font-mono tabular-nums">
            {timeRemaining}
          </p>
        </div>
        
        <div className="pb-3 border-b border-gray-100">
          <p className="text-xs uppercase tracking-wide text-gray-500 mb-1">Logged In As</p>
          <p className="text-sm font-medium text-gray-900 truncate">{user.email}</p>
        </div>
        
        <div className="pb-3 border-b border-gray-100">
          <p className="text-xs uppercase tracking-wide text-gray-500 mb-1">Account Age</p>
          <p className="text-sm font-medium text-gray-900">{getAccountAge()}</p>
        </div>
        
        <div className="pt-2">
          <div className="flex items-center gap-2 text-xs text-gray-500">
            <span className="inline-block w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
            <span>Active session</span>
          </div>
        </div>
      </div>
    </Card>
  );
}
