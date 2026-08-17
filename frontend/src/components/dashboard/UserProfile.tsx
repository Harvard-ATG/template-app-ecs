'use client';

import React from 'react';
import { Card } from '@/components/ui/Card';
import type { User } from '@/lib/types';

interface UserProfileProps {
  user: User;
  sessionId: string;
  sessionExpiry: string;
}

export function UserProfile({ user, sessionId, sessionExpiry }: UserProfileProps) {
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };
  
  const formatDateTime = (dateString: string) => {
    return new Date(dateString).toLocaleString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };
  
  return (
    <Card title="👤 User Profile">
      <div className="space-y-4">
        <div className="pb-3 border-b border-gray-100">
          <p className="text-xs uppercase tracking-wide text-gray-500 mb-1">Email</p>
          <p className="text-sm font-medium text-gray-900">{user.email}</p>
        </div>
        
        <div className="pb-3 border-b border-gray-100">
          <p className="text-xs uppercase tracking-wide text-gray-500 mb-1">Full Name</p>
          <p className="text-sm font-medium text-gray-900">
            {user.full_name || <span className="text-gray-400 italic">Not provided</span>}
          </p>
        </div>
        
        <div className="pb-3 border-b border-gray-100">
          <p className="text-xs uppercase tracking-wide text-gray-500 mb-1">User ID</p>
          <p className="text-sm font-mono text-gray-900">#{user.id}</p>
        </div>
        
        <div className="pb-3 border-b border-gray-100">
          <p className="text-xs uppercase tracking-wide text-gray-500 mb-1">Account Created</p>
          <p className="text-sm font-medium text-gray-900">
            {formatDate(user.created_at)}
          </p>
        </div>
        
        <div>
          <p className="text-xs uppercase tracking-wide text-gray-500 mb-1">Session ID</p>
          <p className="text-xs font-mono text-gray-600 bg-gray-50 px-2 py-1 rounded">
            {sessionId.substring(0, 16)}...
          </p>
        </div>
      </div>
    </Card>
  );
}
