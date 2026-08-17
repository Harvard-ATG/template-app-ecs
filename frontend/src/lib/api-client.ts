/**
 * Type-safe API client
 */
import type { User, SessionData, LoginRequest, RegisterRequest } from './types';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8000';

class APIError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'APIError';
  }
}

async function fetchAPI<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const url = `${API_BASE}${endpoint}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    credentials: 'include',
  });

  if (!response.ok) {
    let errorMessage = 'An error occurred';
    try {
      const errorData = await response.json();
      errorMessage = errorData.detail || errorData.message || errorMessage;
    } catch {
      errorMessage = await response.text() || errorMessage;
    }
    throw new APIError(response.status, errorMessage);
  }

  return response.json();
}

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
