'use client';

import React from 'react';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/Button';

export function Navbar() {
  const { user, logout } = useAuth();

  return (
    <nav className="bg-white shadow-sm border-b border-gray-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo / Brand */}
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <h1 className="text-2xl font-bold text-blue-600">My App</h1>
            </div>
          </div>

          {/* Right side - User menu */}
          <div className="flex items-center space-x-4">
            {user ? (
              <>
                <div className="text-sm text-gray-700">
                  <span className="font-medium">{user.full_name || user.email}</span>
                </div>
                <Button
                  onClick={logout}
                  variant="secondary"
                  size="sm"
                >
                  Logout
                </Button>
              </>
            ) : (
              <div className="text-sm text-gray-500">
                Not logged in
              </div>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}
