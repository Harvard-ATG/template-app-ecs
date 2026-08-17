'use client';

import React, { useState } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { useAuth } from '@/hooks/useAuth';

interface LoginModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function LoginModal({ isOpen, onClose }: LoginModalProps) {
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({});
  
  const { login, register, isLoading, error, clearError } = useAuth();
  
  const validateEmail = (email: string): boolean => {
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return regex.test(email);
  };
  
  const validateForm = (): boolean => {
    const errors: Record<string, string> = {};
    
    if (!email) {
      errors.email = 'Email is required';
    } else if (!validateEmail(email)) {
      errors.email = 'Please enter a valid email';
    }
    
    if (!password) {
      errors.password = 'Password is required';
    } else if (password.length < 12) {
      errors.password = 'Password must be at least 12 characters';
    }
    
    setValidationErrors(errors);
    return Object.keys(errors).length === 0;
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) return;
    
    try {
      if (mode === 'login') {
        await login(email, password);
      } else {
        await register(email, password, fullName || undefined);
      }
      
      // Success - close modal and reset form
      onClose();
      setEmail('');
      setPassword('');
      setFullName('');
      setValidationErrors({});
    } catch (err) {
      // Error is handled by AuthContext
    }
  };
  
  const toggleMode = () => {
    setMode(mode === 'login' ? 'register' : 'login');
    setValidationErrors({});
    clearError();
  };
  
  const handleClose = () => {
    onClose();
    setValidationErrors({});
    clearError();
  };
  
  return (
    <Modal
      isOpen={isOpen}
      onClose={handleClose}
      title={mode === 'login' ? 'Login to Your Account' : 'Create New Account'}
    >
      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Mode Tabs */}
        <div className="flex border-b border-gray-200">
          <button
            type="button"
            onClick={() => {
              setMode('login');
              clearError();
              setValidationErrors({});
            }}
            className={`flex-1 py-2 text-sm font-medium border-b-2 transition-colors ${
              mode === 'login'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
            disabled={isLoading}
          >
            Login
          </button>
          <button
            type="button"
            onClick={() => {
              setMode('register');
              clearError();
              setValidationErrors({});
            }}
            className={`flex-1 py-2 text-sm font-medium border-b-2 transition-colors ${
              mode === 'register'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
            disabled={isLoading}
          >
            Create Account
          </button>
        </div>

        {/* Email Input */}
        <Input
          id="email"
          label="Email Address"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          error={validationErrors.email}
          disabled={isLoading}
          required
          autoComplete="email"
          placeholder="you@example.com"
        />

        {/* Password Input */}
        <Input
          id="password"
          label="Password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          error={validationErrors.password}
          disabled={isLoading}
          required
          autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
          placeholder={mode === 'register' ? 'Minimum 12 characters' : ''}
        />
        
        {/* Full Name (register only) */}
        {mode === 'register' && (
          <Input
            id="fullName"
            label="Full Name"
            type="text"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            disabled={isLoading}
            autoComplete="name"
            placeholder="John Doe"
          />
        )}
        
        {/* API Error */}
        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-md flex items-start">
            <svg className="w-5 h-5 text-red-600 mr-2 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
            </svg>
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}
        
        {/* Submit Button */}
        <Button
          type="submit"
          variant="primary"
          size="lg"
          loading={isLoading}
          disabled={isLoading}
          className="w-full"
        >
          {mode === 'login' ? 'Sign In' : 'Create Account'}
        </Button>
        
        {/* Helper text */}
        {mode === 'register' && (
          <p className="text-xs text-gray-500 text-center">
            By creating an account, you agree to our Terms of Service and Privacy Policy
          </p>
        )}
      </form>
    </Modal>
  );
}
