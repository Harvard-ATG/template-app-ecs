# Interactive Dashboard with Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an interactive React dashboard with modal-based authentication to test and demonstrate the FastAPI auth endpoints.

**Architecture:** React Context for global auth state, custom hooks for cookie management, modal-based login/register flow, three-section dashboard (user profile, stats, LLM playground).

**Tech Stack:** Next.js 16, React 19, TypeScript, Tailwind CSS 4, js-cookie

## Global Constraints

- Node.js >= 20
- TypeScript strict mode enabled
- All components must be client components ('use client' directive)
- API base URL: http://localhost:8000 (development)
- Cookie name: session_id
- Password minimum: 12 characters
- Email validation: standard email regex
- All async operations must have loading states
- All API errors must display user-friendly messages

---

## File Structure Map

**New Files to Create:**
```
frontend/src/
├── components/
│   ├── auth/
│   │   ├── LoginModal.tsx        # Login/register modal
│   │   └── AuthButton.tsx        # Login/logout button
│   ├── dashboard/
│   │   ├── Dashboard.tsx         # Main dashboard container
│   │   ├── UserProfile.tsx       # User info section
│   │   ├── UserStats.tsx         # Stats with countdown
│   │   └── LLMPlayground.tsx     # LLM interface
│   └── ui/
│       ├── Button.tsx            # Reusable button
│       ├── Modal.tsx             # Reusable modal
│       └── Card.tsx              # Dashboard card
├── contexts/
│   └── AuthContext.tsx           # Auth state management
├── hooks/
│   ├── useAuth.ts                # Auth context hook
│   └── useSessionCookie.ts       # Cookie operations
└── lib/
    └── types.ts                  # TypeScript interfaces
```

**Files to Modify:**
```
frontend/
├── package.json                  # Add js-cookie dependency
├── src/app/layout.tsx            # Wrap with AuthProvider
├── src/app/page.tsx              # Add conditional rendering
└── src/lib/api-client.ts         # Add proper types
```

---

### Task 1: Install Dependencies and Setup Types

**Files:**
- Modify: `frontend/package.json`
- Create: `frontend/src/lib/types.ts`

**Interfaces:**
- Consumes: Nothing (foundation task)
- Produces: 
  - TypeScript types: `User`, `SessionData`, `AuthContextType`, `LoginResponse`, `RegisterResponse`
  - js-cookie library available

- [ ] **Step 1: Install js-cookie dependency**

```bash
cd frontend
npm install js-cookie
npm install --save-dev @types/js-cookie
```

Expected output: Dependencies added to package.json and node_modules

- [ ] **Step 2: Create TypeScript types file**

Create `frontend/src/lib/types.ts`:

```typescript
// User data from API
export interface User {
  id: number;
  email: string;
  full_name?: string;
  created_at: string;
}

// Session data from login response
export interface SessionData {
  user: User;
  session_id: string;
  expires_at: string;
}

// Login API request
export interface LoginRequest {
  email: string;
  password: string;
}

// Register API request
export interface RegisterRequest {
  email: string;
  password: string;
  full_name?: string;
}

// Auth context interface
export interface AuthContextType {
  user: User | null;
  sessionId: string | null;
  sessionExpiry: string | null;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, fullName?: string) => Promise<void>;
  logout: () => Promise<void>;
  clearError: () => void;
}

// API Error
export class APIError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'APIError';
  }
}
```

- [ ] **Step 3: Verify types compile**

```bash
cd frontend
npm run typecheck
```

Expected: No TypeScript errors

- [ ] **Step 4: Commit**

```bash
git add frontend/package.json frontend/package-lock.json frontend/src/lib/types.ts
git commit -m "feat: add js-cookie dependency and TypeScript types for auth"
```

---

### Task 2: Create Session Cookie Hook

**Files:**
- Create: `frontend/src/hooks/useSessionCookie.ts`

**Interfaces:**
- Consumes: js-cookie library
- Produces:
  - `useSessionCookie()` hook returning `{ getSessionId, setSessionId, removeSessionId }`
  - `getSessionId(): string | null`
  - `setSessionId(sessionId: string, expiresAt: string): void`
  - `removeSessionId(): void`

- [ ] **Step 1: Create cookie hook file**

Create `frontend/src/hooks/useSessionCookie.ts`:

```typescript
'use client';

import Cookies from 'js-cookie';

const COOKIE_NAME = 'session_id';

export function useSessionCookie() {
  const getSessionId = (): string | null => {
    return Cookies.get(COOKIE_NAME) || null;
  };

  const setSessionId = (sessionId: string, expiresAt: string): void => {
    // Calculate expiry from ISO timestamp
    const expiryDate = new Date(expiresAt);
    const now = new Date();
    const daysUntilExpiry = (expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
    
    Cookies.set(COOKIE_NAME, sessionId, {
      expires: daysUntilExpiry,
      sameSite: 'strict',
      secure: false, // Set to true in production with HTTPS
    });
  };

  const removeSessionId = (): void => {
    Cookies.remove(COOKIE_NAME);
  };

  return {
    getSessionId,
    setSessionId,
    removeSessionId,
  };
}
```

- [ ] **Step 2: Verify hook compiles**

```bash
cd frontend
npm run typecheck
```

Expected: No TypeScript errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/hooks/useSessionCookie.ts
git commit -m "feat: add session cookie management hook"
```

---

### Task 3: Update API Client with Types

**Files:**
- Modify: `frontend/src/lib/api-client.ts`

**Interfaces:**
- Consumes: Types from `lib/types.ts`
- Produces:
  - `api.auth.register(data: RegisterRequest): Promise<User>`
  - `api.auth.login(data: LoginRequest): Promise<SessionData>`
  - `api.auth.logout(sessionId: string): Promise<{ status: string }>`
  - `api.llm.complete(data: { prompt: string }): Promise<{ content: string; model: string }>`

- [ ] **Step 1: Import types into API client**

Modify `frontend/src/lib/api-client.ts` - add imports at top:

```typescript
import type { User, SessionData, LoginRequest, RegisterRequest } from './types';
```

- [ ] **Step 2: Add proper type annotations to API methods**

Replace the existing `api` object in `frontend/src/lib/api-client.ts`:

```typescript
export const api = {
  health: () => fetchAPI<{ status: string; database: string }>('/api/v1/health'),
  
  auth: {
    register: (data: RegisterRequest) =>
      fetchAPI<User>('/api/v1/auth/register', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    
    login: (data: LoginRequest) =>
      fetchAPI<SessionData>('/api/v1/auth/login', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    
    logout: (sessionId: string) =>
      fetchAPI<{ status: string }>('/api/v1/auth/logout', {
        method: 'POST',
        body: JSON.stringify({ session_id: sessionId }),
      }),
  },
  
  llm: {
    complete: (data: { prompt: string; stream?: boolean }) =>
      fetchAPI<{ content: string; model: string; usage: Record<string, number> }>('/api/v1/llm/complete', {
        method: 'POST',
        body: JSON.stringify({ ...data, stream: false }),
      }),
  },
};
```

- [ ] **Step 3: Verify types compile**

```bash
cd frontend
npm run typecheck
```

Expected: No TypeScript errors

- [ ] **Step 4: Commit**

```bash
git add frontend/src/lib/api-client.ts
git commit -m "feat: add TypeScript types to API client"
```

---

### Task 4: Create Auth Context

**Files:**
- Create: `frontend/src/contexts/AuthContext.tsx`
- Create: `frontend/src/hooks/useAuth.ts`

**Interfaces:**
- Consumes:
  - `api.auth.*` from `lib/api-client.ts`
  - `useSessionCookie()` from `hooks/useSessionCookie.ts`
  - Types from `lib/types.ts`
- Produces:
  - `AuthProvider` component
  - `useAuth()` hook returning `AuthContextType`

- [ ] **Step 1: Create AuthContext file**

Create `frontend/src/contexts/AuthContext.tsx`:

```typescript
'use client';

import React, { createContext, useState, useEffect, useCallback } from 'react';
import type { AuthContextType, User } from '@/lib/types';
import { api } from '@/lib/api-client';
import { useSessionCookie } from '@/hooks/useSessionCookie';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [sessionExpiry, setSessionExpiry] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const { getSessionId, setSessionId: saveSessionCookie, removeSessionId } = useSessionCookie();

  // Check for existing session on mount
  useEffect(() => {
    const existingSessionId = getSessionId();
    if (existingSessionId) {
      setSessionId(existingSessionId);
      // In a real app, you'd validate the session here
      // For now, we trust the cookie exists
    }
  }, [getSessionId]);

  const login = useCallback(async (email: string, password: string) => {
    setIsLoading(true);
    setError(null);
    
    try {
      const data = await api.auth.login({ email, password });
      
      // Save to cookie
      saveSessionCookie(data.session_id, data.expires_at);
      
      // Update context
      setUser(data.user);
      setSessionId(data.session_id);
      setSessionExpiry(data.expires_at);
    } catch (err: any) {
      const message = err.status === 401 
        ? 'Invalid email or password'
        : 'Unable to login. Please try again.';
      setError(message);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, [saveSessionCookie]);

  const register = useCallback(async (email: string, password: string, fullName?: string) => {
    setIsLoading(true);
    setError(null);
    
    try {
      await api.auth.register({ email, password, full_name: fullName });
      
      // After successful registration, log in
      await login(email, password);
    } catch (err: any) {
      const message = err.status === 400
        ? 'Email already registered'
        : 'Unable to register. Please try again.';
      setError(message);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, [login]);

  const logout = useCallback(async () => {
    if (!sessionId) return;
    
    setIsLoading(true);
    
    try {
      await api.auth.logout(sessionId);
    } catch (err) {
      // Even if API call fails, clear local state
      console.error('Logout error:', err);
    } finally {
      // Clear everything
      removeSessionId();
      setUser(null);
      setSessionId(null);
      setSessionExpiry(null);
      setIsLoading(false);
    }
  }, [sessionId, removeSessionId]);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  const value: AuthContextType = {
    user,
    sessionId,
    sessionExpiry,
    isLoading,
    error,
    login,
    register,
    logout,
    clearError,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export { AuthContext };
```

- [ ] **Step 2: Create useAuth hook**

Create `frontend/src/hooks/useAuth.ts`:

```typescript
'use client';

import { useContext } from 'react';
import { AuthContext } from '@/contexts/AuthContext';

export function useAuth() {
  const context = useContext(AuthContext);
  
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  
  return context;
}
```

- [ ] **Step 3: Verify context compiles**

```bash
cd frontend
npm run typecheck
```

Expected: No TypeScript errors

- [ ] **Step 4: Commit**

```bash
git add frontend/src/contexts/AuthContext.tsx frontend/src/hooks/useAuth.ts
git commit -m "feat: add auth context and useAuth hook"
```

---

### Task 5: Create UI Components (Button, Modal, Card)

**Files:**
- Create: `frontend/src/components/ui/Button.tsx`
- Create: `frontend/src/components/ui/Modal.tsx`
- Create: `frontend/src/components/ui/Card.tsx`

**Interfaces:**
- Consumes: Nothing
- Produces:
  - `Button` component: `props { variant: 'primary' | 'secondary' | 'danger', onClick, disabled, loading, children }`
  - `Modal` component: `props { isOpen, onClose, title, children }`
  - `Card` component: `props { title, children, className? }`

- [ ] **Step 1: Create Button component**

Create `frontend/src/components/ui/Button.tsx`:

```typescript
'use client';

import React from 'react';

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger';
  onClick?: () => void;
  disabled?: boolean;
  loading?: boolean;
  type?: 'button' | 'submit' | 'reset';
  children: React.ReactNode;
  className?: string;
}

export function Button({
  variant = 'primary',
  onClick,
  disabled = false,
  loading = false,
  type = 'button',
  children,
  className = '',
}: ButtonProps) {
  const baseClasses = 'px-4 py-2 rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2';
  
  const variantClasses = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 disabled:bg-blue-300',
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500 disabled:bg-gray-100',
    danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500 disabled:bg-red-300',
  };
  
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled || loading}
      className={`${baseClasses} ${variantClasses[variant]} ${className}`}
    >
      {loading ? (
        <span className="flex items-center justify-center">
          <svg className="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
          Loading...
        </span>
      ) : (
        children
      )}
    </button>
  );
}
```

- [ ] **Step 2: Create Modal component**

Create `frontend/src/components/ui/Modal.tsx`:

```typescript
'use client';

import React, { useEffect } from 'react';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}

export function Modal({ isOpen, onClose, title, children }: ModalProps) {
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    
    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden';
    }
    
    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, onClose]);
  
  if (!isOpen) return null;
  
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black bg-opacity-50 backdrop-blur-sm"
        onClick={onClose}
      />
      
      {/* Modal */}
      <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4 p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-gray-900">{title}</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
            aria-label="Close modal"
          >
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        
        {children}
      </div>
    </div>
  );
}
```

- [ ] **Step 3: Create Card component**

Create `frontend/src/components/ui/Card.tsx`:

```typescript
'use client';

import React from 'react';

interface CardProps {
  title: string;
  children: React.ReactNode;
  className?: string;
}

export function Card({ title, children, className = '' }: CardProps) {
  return (
    <div className={`bg-white rounded-lg border border-gray-200 shadow-sm p-6 ${className}`}>
      <h3 className="text-xl font-bold text-gray-900 mb-4">{title}</h3>
      {children}
    </div>
  );
}
```

- [ ] **Step 4: Verify components compile**

```bash
cd frontend
npm run typecheck
```

Expected: No TypeScript errors

- [ ] **Step 5: Commit**

```bash
git add frontend/src/components/ui/
git commit -m "feat: add reusable UI components (Button, Modal, Card)"
```

---

### Task 6: Create Login Modal Component

**Files:**
- Create: `frontend/src/components/auth/LoginModal.tsx`

**Interfaces:**
- Consumes:
  - `Button` from `components/ui/Button.tsx`
  - `Modal` from `components/ui/Modal.tsx`
  - `useAuth()` from `hooks/useAuth.ts`
- Produces:
  - `LoginModal` component: `props { isOpen, onClose }`

- [ ] **Step 1: Create LoginModal component**

Create `frontend/src/components/auth/LoginModal.tsx`:

```typescript
'use client';

import React, { useState } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
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
      title={mode === 'login' ? 'Login' : 'Register'}
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Email */}
        <div>
          <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            disabled={isLoading}
          />
          {validationErrors.email && (
            <p className="mt-1 text-sm text-red-600">{validationErrors.email}</p>
          )}
        </div>
        
        {/* Password */}
        <div>
          <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
            Password
          </label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            disabled={isLoading}
          />
          {validationErrors.password && (
            <p className="mt-1 text-sm text-red-600">{validationErrors.password}</p>
          )}
        </div>
        
        {/* Full Name (register only) */}
        {mode === 'register' && (
          <div>
            <label htmlFor="fullName" className="block text-sm font-medium text-gray-700 mb-1">
              Full Name (optional)
            </label>
            <input
              id="fullName"
              type="text"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={isLoading}
            />
          </div>
        )}
        
        {/* API Error */}
        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-md">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}
        
        {/* Submit Button */}
        <Button
          type="submit"
          variant="primary"
          loading={isLoading}
          disabled={isLoading}
          className="w-full"
        >
          {mode === 'login' ? 'Login' : 'Register'}
        </Button>
        
        {/* Toggle Mode */}
        <div className="text-center">
          <button
            type="button"
            onClick={toggleMode}
            className="text-sm text-blue-600 hover:text-blue-700"
            disabled={isLoading}
          >
            {mode === 'login' 
              ? "Don't have an account? Register" 
              : "Already have an account? Login"}
          </button>
        </div>
      </form>
    </Modal>
  );
}
```

- [ ] **Step 2: Verify component compiles**

```bash
cd frontend
npm run typecheck
```

Expected: No TypeScript errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/auth/LoginModal.tsx
git commit -m "feat: add login/register modal component"
```

---

### Task 7: Create Dashboard Components

**Files:**
- Create: `frontend/src/components/dashboard/Dashboard.tsx`
- Create: `frontend/src/components/dashboard/UserProfile.tsx`
- Create: `frontend/src/components/dashboard/UserStats.tsx`
- Create: `frontend/src/components/dashboard/LLMPlayground.tsx`

**Interfaces:**
- Consumes:
  - `Card` from `components/ui/Card.tsx`
  - `Button` from `components/ui/Button.tsx`
  - `useAuth()` from `hooks/useAuth.ts`
  - `api.llm.complete` from `lib/api-client.ts`
  - Types from `lib/types.ts`
- Produces:
  - `Dashboard` component (no props)
  - `UserProfile` component: `props { user, sessionId, sessionExpiry }`
  - `UserStats` component: `props { user, sessionExpiry }`
  - `LLMPlayground` component (no props)

- [ ] **Step 1: Create UserProfile component**

Create `frontend/src/components/dashboard/UserProfile.tsx`:

```typescript
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
    <Card title="User Profile">
      <div className="space-y-3">
        <div>
          <p className="text-sm text-gray-600">Email</p>
          <p className="text-base font-medium text-gray-900">{user.email}</p>
        </div>
        
        <div>
          <p className="text-sm text-gray-600">Full Name</p>
          <p className="text-base font-medium text-gray-900">
            {user.full_name || 'Not provided'}
          </p>
        </div>
        
        <div>
          <p className="text-sm text-gray-600">Account Created</p>
          <p className="text-base font-medium text-gray-900">
            {formatDate(user.created_at)}
          </p>
        </div>
        
        <div>
          <p className="text-sm text-gray-600">Session ID</p>
          <p className="text-base font-mono text-gray-900">
            {sessionId.substring(0, 8)}...
          </p>
        </div>
        
        <div>
          <p className="text-sm text-gray-600">Session Expires</p>
          <p className="text-base font-medium text-gray-900">
            {formatDateTime(sessionExpiry)}
          </p>
        </div>
      </div>
    </Card>
  );
}
```

- [ ] **Step 2: Create UserStats component**

Create `frontend/src/components/dashboard/UserStats.tsx`:

```typescript
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
    <Card title="Session Stats">
      <div className="space-y-4">
        <div>
          <p className="text-sm text-gray-600">Logged in as</p>
          <p className="text-base font-medium text-gray-900">{user.email}</p>
        </div>
        
        <div>
          <p className="text-sm text-gray-600">Account age</p>
          <p className="text-base font-medium text-gray-900">{getAccountAge()}</p>
        </div>
        
        <div>
          <p className="text-sm text-gray-600">Session expires in</p>
          <p className="text-base font-medium text-gray-900 font-mono">
            {timeRemaining}
          </p>
        </div>
      </div>
    </Card>
  );
}
```

- [ ] **Step 3: Create LLMPlayground component**

Create `frontend/src/components/dashboard/LLMPlayground.tsx`:

```typescript
'use client';

import React, { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { api } from '@/lib/api-client';

export function LLMPlayground() {
  const [prompt, setPrompt] = useState('');
  const [response, setResponse] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  
  const MAX_PROMPT_LENGTH = 10000;
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!prompt.trim()) return;
    
    setIsLoading(true);
    setError('');
    setResponse('');
    
    try {
      const data = await api.llm.complete({ prompt });
      setResponse(data.content);
    } catch (err: any) {
      if (err.status === 503) {
        setError('LLM service not configured. Set APP_ANTHROPIC_API_KEY to enable.');
      } else {
        setError('Unable to reach API. Is the server running?');
      }
    } finally {
      setIsLoading(false);
    }
  };
  
  const handleClear = () => {
    setPrompt('');
    setResponse('');
    setError('');
  };
  
  return (
    <Card title="LLM Playground">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="prompt" className="block text-sm font-medium text-gray-700 mb-1">
            Prompt
          </label>
          <textarea
            id="prompt"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            rows={4}
            maxLength={MAX_PROMPT_LENGTH}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Enter your prompt here..."
            disabled={isLoading}
          />
          <p className="mt-1 text-xs text-gray-500">
            {prompt.length} / {MAX_PROMPT_LENGTH} characters
          </p>
        </div>
        
        <div className="flex gap-2">
          <Button
            type="submit"
            variant="primary"
            loading={isLoading}
            disabled={isLoading || !prompt.trim()}
          >
            Submit
          </Button>
          <Button
            type="button"
            variant="secondary"
            onClick={handleClear}
            disabled={isLoading}
          >
            Clear
          </Button>
        </div>
        
        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-md">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}
        
        {response && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Response
            </label>
            <div className="p-4 bg-gray-50 border border-gray-200 rounded-md">
              <p className="text-sm text-gray-900 whitespace-pre-wrap">{response}</p>
            </div>
          </div>
        )}
      </form>
    </Card>
  );
}
```

- [ ] **Step 4: Create Dashboard container**

Create `frontend/src/components/dashboard/Dashboard.tsx`:

```typescript
'use client';

import React from 'react';
import { useAuth } from '@/hooks/useAuth';
import { UserProfile } from './UserProfile';
import { UserStats } from './UserStats';
import { LLMPlayground } from './LLMPlayground';
import { Button } from '@/components/ui/Button';

export function Dashboard() {
  const { user, sessionId, sessionExpiry, logout, isLoading } = useAuth();
  
  if (!user || !sessionId || !sessionExpiry) {
    return null;
  }
  
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-200 py-4 px-8">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <Button
            variant="secondary"
            onClick={logout}
            disabled={isLoading}
          >
            Logout
          </Button>
        </div>
      </header>
      
      <main className="max-w-7xl mx-auto py-8 px-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <UserProfile
            user={user}
            sessionId={sessionId}
            sessionExpiry={sessionExpiry}
          />
          <UserStats
            user={user}
            sessionExpiry={sessionExpiry}
          />
          <LLMPlayground />
        </div>
      </main>
    </div>
  );
}
```

- [ ] **Step 5: Verify all dashboard components compile**

```bash
cd frontend
npm run typecheck
```

Expected: No TypeScript errors

- [ ] **Step 6: Commit**

```bash
git add frontend/src/components/dashboard/
git commit -m "feat: add dashboard components (UserProfile, UserStats, LLMPlayground)"
```

---

### Task 8: Create Auth Button and Wire Up Homepage

**Files:**
- Create: `frontend/src/components/auth/AuthButton.tsx`
- Modify: `frontend/src/app/layout.tsx`
- Modify: `frontend/src/app/page.tsx`

**Interfaces:**
- Consumes:
  - `AuthProvider` from `contexts/AuthContext.tsx`
  - `useAuth()` from `hooks/useAuth.ts`
  - `LoginModal` from `components/auth/LoginModal.tsx`
  - `Dashboard` from `components/dashboard/Dashboard.tsx`
  - `Button` from `components/ui/Button.tsx`
- Produces: Complete working application

- [ ] **Step 1: Create AuthButton component**

Create `frontend/src/components/auth/AuthButton.tsx`:

```typescript
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
        onClick={() => setIsModalOpen(true)}
      >
        Login
      </Button>
      
      <LoginModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
      />
    </>
  );
}
```

- [ ] **Step 2: Update root layout with AuthProvider**

Modify `frontend/src/app/layout.tsx` - replace entire file:

```typescript
import type { Metadata } from 'next';
import './globals.css';
import { AuthProvider } from '@/contexts/AuthContext';

export const metadata: Metadata = {
  title: 'My App',
  description: 'Full-stack application with authentication',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>
          {children}
        </AuthProvider>
      </body>
    </html>
  );
}
```

- [ ] **Step 3: Update homepage with conditional rendering**

Modify `frontend/src/app/page.tsx` - replace entire file:

```typescript
'use client';

import { useAuth } from '@/hooks/useAuth';
import { Dashboard } from '@/components/dashboard/Dashboard';
import { AuthButton } from '@/components/auth/AuthButton';

export default function Home() {
  const { user } = useAuth();
  
  if (user) {
    return <Dashboard />;
  }
  
  return (
    <main className="min-h-screen bg-gray-50 flex items-center justify-center p-8">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          Welcome to My App
        </h1>
        <p className="text-lg text-gray-600 mb-8">
          Full-stack application with FastAPI + Next.js + LLM
        </p>
        <AuthButton />
      </div>
    </main>
  );
}
```

- [ ] **Step 4: Verify entire app compiles**

```bash
cd frontend
npm run typecheck
```

Expected: No TypeScript errors

- [ ] **Step 5: Build the app**

```bash
cd frontend
npm run build
```

Expected: Build succeeds with no errors

- [ ] **Step 6: Commit**

```bash
git add frontend/src/app/layout.tsx frontend/src/app/page.tsx frontend/src/components/auth/AuthButton.tsx
git commit -m "feat: wire up homepage with auth and dashboard"
```

---

### Task 9: Manual Testing and Verification

**Files:**
- No file changes

**Interfaces:**
- Consumes: Complete application from Task 8
- Produces: Verified working application

- [ ] **Step 1: Start Docker services**

```bash
docker-compose up -d
```

Wait for services to be healthy (~30 seconds):
```bash
docker-compose ps
```

Expected: All services show "healthy" or "Up"

- [ ] **Step 2: Start frontend dev server**

```bash
cd frontend
npm run dev
```

Expected: Server starts on http://localhost:3000

- [ ] **Step 3: Test registration flow**

1. Open http://localhost:3000 in browser
2. Click "Login" button
3. Click "Don't have an account? Register"
4. Enter:
   - Email: `test@example.com`
   - Password: `testpassword123`
   - Full Name: `Test User`
5. Click "Register"

Expected: Modal closes, dashboard appears with user data

- [ ] **Step 4: Verify dashboard data**

Check that dashboard shows:
- Email: test@example.com
- Full Name: Test User
- Account Created: Today's date
- Session ID: First 8 characters + "..."
- Session Expires: Date 24 hours from now
- Session countdown timer updating every second

Expected: All data displays correctly

- [ ] **Step 5: Test LLM playground (without API key)**

1. In LLM Playground section, enter prompt: "Hello, world!"
2. Click "Submit"

Expected: Error message "LLM service not configured. Set APP_ANTHROPIC_API_KEY to enable."

- [ ] **Step 6: Test logout**

1. Click "Logout" button in header
2. Observe page returns to login state

Expected: Dashboard disappears, "Login" button appears

- [ ] **Step 7: Test login flow**

1. Click "Login" button
2. Enter:
   - Email: `test@example.com`
   - Password: `testpassword123`
3. Click "Login"

Expected: Modal closes, dashboard appears again

- [ ] **Step 8: Test session persistence**

1. While logged in, refresh the page (F5)

Expected: User stays logged in, dashboard remains visible

- [ ] **Step 9: Test form validation**

1. Logout
2. Click "Login"
3. Try submitting empty form

Expected: Validation errors appear

4. Enter invalid email: `notanemail`

Expected: Email validation error appears

5. Enter short password: `short`

Expected: Password length error appears

- [ ] **Step 10: Test error handling**

1. Stop the API server: `docker-compose stop api`
2. Try to login

Expected: Error message about unable to connect

3. Restart API: `docker-compose start api`

- [ ] **Step 11: Open browser DevTools and check for errors**

1. Open DevTools (F12)
2. Go to Console tab
3. Interact with the app

Expected: No console errors (warnings are OK)

- [ ] **Step 12: Test responsive design**

1. Open DevTools
2. Toggle device toolbar (mobile view)
3. Check layout on different screen sizes

Expected:
- Mobile: Cards stack vertically
- Desktop: Cards in 3 columns
- Modal: Full width on mobile, constrained on desktop

- [ ] **Step 13: Verify cookie is set**

1. Login
2. Open DevTools → Application tab → Cookies
3. Check cookies for localhost:3000

Expected: Cookie named `session_id` with UUID value

- [ ] **Step 14: Document any issues found**

If any tests fail, document:
- What went wrong
- Steps to reproduce
- Expected vs actual behavior

---

### Task 10: Optional - Test with LLM API Key

**Files:**
- Modify: `.env` (in project root)

**Interfaces:**
- Consumes: Complete application
- Produces: Verified LLM functionality

- [ ] **Step 1: Add Anthropic API key**

Edit `.env` file in project root:

```bash
APP_ANTHROPIC_API_KEY=sk-ant-your-key-here
```

- [ ] **Step 2: Restart API service**

```bash
docker-compose restart api
```

- [ ] **Step 3: Check API logs for LLM status**

```bash
docker-compose logs api | grep LLM
```

Expected: "LLM features enabled - Anthropic API key configured"

- [ ] **Step 4: Test LLM playground**

1. Login to dashboard
2. In LLM Playground, enter prompt: "What is 2+2? Answer in one sentence."
3. Click "Submit"

Expected: AI-generated response appears (e.g., "2+2 equals 4.")

- [ ] **Step 5: Test character limit**

1. Enter a very long prompt (>10,000 characters)

Expected: Textarea prevents input beyond limit, counter shows 10000/10000

- [ ] **Step 6: Test clear button**

1. Enter prompt and get response
2. Click "Clear"

Expected: Prompt and response both clear

---

## Post-Implementation Verification

After completing all tasks, verify:

1. **All files created:**
   - [ ] 17 new component/hook/context files
   - [ ] 1 types file
   - [ ] package.json updated

2. **No TypeScript errors:**
   ```bash
   cd frontend && npm run typecheck
   ```

3. **Build succeeds:**
   ```bash
   cd frontend && npm run build
   ```

4. **All functionality works:**
   - [ ] Register new user
   - [ ] Login existing user
   - [ ] Logout
   - [ ] Session persistence
   - [ ] Dashboard displays data
   - [ ] LLM playground (with/without API key)
   - [ ] Form validation
   - [ ] Error handling
   - [ ] Responsive design

5. **Code quality:**
   - [ ] No console errors
   - [ ] No unused imports
   - [ ] Consistent code style
   - [ ] All components properly typed

## Success Criteria

Implementation is complete when:
- All tasks are checked off
- All manual tests pass
- User can register, login, logout, and see dashboard
- Session persists across page refreshes
- Dashboard shows user info, stats with live countdown, and LLM playground
- LLM playground handles both configured and unconfigured states gracefully
- No TypeScript errors or console warnings
- Responsive design works on mobile and desktop
- Form validation provides clear feedback
- Error messages are user-friendly

The application serves as a complete, working example of authentication with React Context, demonstrating modern React patterns and best practices for building full-stack applications.
