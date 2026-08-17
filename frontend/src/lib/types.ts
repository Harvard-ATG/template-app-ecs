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
