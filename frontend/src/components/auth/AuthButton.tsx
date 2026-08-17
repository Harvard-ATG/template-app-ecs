'use client';

import React, { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { LoginModal } from './LoginModal';
import { useAuth } from '@/hooks/useAuth';

export function AuthButton() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const { user, logout, isLoading } = useAuth();
  
  if (user) {
    return (
      <Button
        variant="secondary"
        size="lg"
        onClick={logout}
        disabled={isLoading}
      >
        Logout
      </Button>
    );
  }
  
  return (
    <>
      <Button
        variant="primary"
        size="lg"
        onClick={() => setIsModalOpen(true)}
        className="shadow-lg hover:shadow-xl transition-shadow"
      >
        Get Started - Sign In
      </Button>
      
      <LoginModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
      />
    </>
  );
}
