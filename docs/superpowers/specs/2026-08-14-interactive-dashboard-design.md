# Interactive Dashboard with Authentication - Design Specification

**Date:** 2026-08-14  
**Project:** Full-Stack Application Template (FastAPI + Next.js + LLM)  
**Feature:** Interactive frontend with login modal and comprehensive dashboard

## Overview

Build an interactive React-based dashboard interface to demonstrate and test the authentication functionality of the FastAPI backend. The interface will include a modal-based login/registration system, user profile display, stats tracking, and a simple LLM playground—all using cookie-based session persistence and React Context for state management.

## Goals

1. Provide a complete authentication testing interface (register, login, logout)
2. Demonstrate session persistence across page refreshes using cookies
3. Display user information and session data in a clear dashboard
4. Include a simple LLM playground to test the optional AI features
5. Create a maintainable, well-structured React codebase following best practices
6. Serve as a learning example of modern React patterns (Context, custom hooks)

## Non-Goals

- Server-side rendering or static site generation
- Complex state management libraries (Redux, Zustand, etc.)
- Advanced LLM features (streaming, conversation history, model selection)
- User profile editing or account management beyond auth
- Production-ready security (this is for local testing/learning)

## Architecture

### Technology Stack

- **Framework:** Next.js 16 with App Router
- **State Management:** React Context API
- **Styling:** Tailwind CSS 4
- **HTTP Client:** Fetch API (existing api-client.ts)
- **Cookie Management:** `js-cookie` library
- **TypeScript:** Full type safety throughout

### Component Architecture

```
src/
├── app/
│   ├── layout.tsx              # Root layout with AuthProvider wrapper
│   └── page.tsx                # Home page (conditional: login button or dashboard)
├── components/
│   ├── auth/
│   │   ├── LoginModal.tsx      # Modal with login/register forms
│   │   └── AuthButton.tsx      # Login/Logout button in header
│   ├── dashboard/
│   │   ├── Dashboard.tsx       # Main dashboard container
│   │   ├── UserProfile.tsx     # User info display (email, name, dates)
│   │   ├── UserStats.tsx       # Session stats (expiry, account age)
│   │   └── LLMPlayground.tsx   # Simple prompt/response interface
│   └── ui/
│       ├── Button.tsx          # Reusable button component
│       ├── Modal.tsx           # Reusable modal wrapper
│       └── Card.tsx            # Dashboard card container
├── contexts/
│   └── AuthContext.tsx         # Global auth state and operations
├── hooks/
│   ├── useAuth.ts              # Hook to access auth context
│   └── useSessionCookie.ts     # Cookie management utilities
└── lib/
    ├── api-client.ts           # Existing API client (enhance types)
    └── types.ts                # Shared TypeScript interfaces
```

### Data Flow

1. **App Load:** 
   - AuthProvider checks for session cookie
   - If found, validates session (could call health endpoint)
   - Sets initial auth state

2. **Login:**
   - User submits form in LoginModal
   - AuthContext calls `api.auth.login()`
   - On success, stores session_id in cookie
   - Updates context with user data
   - Modal closes, dashboard appears

3. **Page Refresh:**
   - AuthProvider reads session cookie
   - Restores session state
   - User remains logged in

4. **Logout:**
   - User clicks logout
   - AuthContext calls `api.auth.logout()`
   - Removes session cookie
   - Clears context state
   - Shows login UI

## Detailed Component Specifications

### 1. AuthContext (contexts/AuthContext.tsx)

**Purpose:** Centralize authentication state and operations for the entire application.

**Interface:**
```typescript
interface User {
  id: number;
  email: string;
  full_name?: string;
  created_at: string;
}

interface AuthContextType {
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
```

**Responsibilities:**
- Manage auth state (user, sessionId, sessionExpiry, loading, error)
- Provide login, register, logout methods
- Sync session cookie with context state
- Handle API errors and expose them to components
- Prevent concurrent auth operations (check isLoading)

**Implementation Notes:**
- Use `useState` for each piece of state
- Use `useEffect` to check session cookie on mount
- All async operations should set `isLoading` true/false
- Catch API errors and set `error` state with user-friendly messages
- On successful auth, call `setSessionId()` from cookie hook

### 2. useSessionCookie Hook (hooks/useSessionCookie.ts)

**Purpose:** Encapsulate all cookie operations for session management.

**Interface:**
```typescript
interface SessionCookieHook {
  getSessionId: () => string | null;
  setSessionId: (sessionId: string, expiresAt: string) => void;
  removeSessionId: () => void;
}
```

**Implementation:**
- Use `js-cookie` library for cookie operations
- Cookie name: `session_id`
- Cookie attributes: `{ sameSite: 'strict', secure: false }` (secure=false for local dev)
- Calculate expiry from API's `expires_at` timestamp
- Handle both setting and getting session ID

### 3. LoginModal Component (components/auth/LoginModal.tsx)

**Purpose:** Modal dialog with login and register forms.

**Props:**
```typescript
interface LoginModalProps {
  isOpen: boolean;
  onClose: () => void;
}
```

**Features:**
- Toggle between "Login" and "Register" modes with a button
- **Login Form:** Email, password fields
- **Register Form:** Email, password, optional full name fields
- Client-side validation:
  - Email format validation
  - Password minimum 12 characters
  - Show validation errors inline
- Submit button with loading state
- Display API errors (from AuthContext.error)
- Close button and backdrop click to dismiss
- Keyboard support (Escape to close)

**State Management:**
- Local state for form mode ("login" | "register")
- Local state for form fields (email, password, fullName)
- Local state for validation errors
- Use AuthContext methods (login, register)
- Use AuthContext.isLoading for button disabled state
- Use AuthContext.error for displaying API errors

**UI Design:**
- Centered modal with backdrop blur
- Clean form layout with labels
- Primary button for submit
- Secondary button to toggle login/register
- Error messages in red below fields
- Loading spinner on submit button

### 4. Dashboard Component (components/dashboard/Dashboard.tsx)

**Purpose:** Container for all dashboard sections.

**Layout:**
- Three-column responsive grid (stacks on mobile)
- Equal-height cards for each section
- Consistent spacing and styling
- Header with app title and logout button

**Sections:**
1. UserProfile (left)
2. UserStats (middle)
3. LLMPlayground (right)

**Implementation:**
- Simple layout component
- Passes user data from AuthContext to child components
- No local state, just layout and composition

### 5. UserProfile Component (components/dashboard/UserProfile.tsx)

**Purpose:** Display current user information.

**Data Displayed:**
- Email address
- Full name (if provided, otherwise "Not provided")
- Account creation date (formatted: "January 15, 2026")
- Session ID (truncated: first 8 characters + "...")
- Session expiry date/time (formatted)

**Styling:**
- Card-based layout
- Icon for each piece of info (optional, can use emojis)
- Monospace font for session ID
- Clear labels for each field

**Implementation:**
- Receives `user` and `sessionId`, `sessionExpiry` from props
- Uses date formatting utilities
- No local state

### 6. UserStats Component (components/dashboard/UserStats.tsx)

**Purpose:** Display session statistics and account info.

**Stats Displayed:**
- "Logged in as: [email]"
- "Account age: X days ago"
- "Session expires in: X hours Y minutes" (live countdown)

**Implementation:**
- Countdown timer using `setInterval`
- Calculate time difference between now and expiry
- Update every second for live countdown
- Format relative dates for account age
- Clean up interval on unmount

**State:**
- Local state for current time (updates every second)

### 7. LLMPlayground Component (components/dashboard/LLMPlayground.tsx)

**Purpose:** Simple interface to test LLM completion endpoint.

**UI Elements:**
- Text area for prompt input (multiline)
- "Submit" button
- Response display area (read-only, styled)
- Loading state while waiting for API
- Error display for 503 (LLM not configured)

**Features:**
- Clear prompt button
- Character count on prompt (show remaining: max 10,000)
- Disabled submit if prompt is empty
- Display loading spinner during API call
- Show formatted response
- Handle 503 gracefully with helpful message

**State Management:**
- Local state for prompt text
- Local state for response
- Local state for loading
- Local state for error
- Call `api.llm.complete()` on submit

**Error Handling:**
- 503: "LLM not configured. Add APP_ANTHROPIC_API_KEY to enable."
- Network errors: "Unable to reach API. Is the server running?"
- Other errors: Display error message from API

### 8. Reusable UI Components

**Button (components/ui/Button.tsx):**
- Props: variant ('primary' | 'secondary' | 'danger'), onClick, disabled, loading, children
- Styles: Tailwind classes for variants
- Loading state: Show spinner, disable interaction
- Disabled state: Opacity and no pointer events

**Modal (components/ui/Modal.tsx):**
- Props: isOpen, onClose, title, children
- Features: Backdrop, close button, keyboard support (Escape)
- Styling: Centered, backdrop blur, smooth transitions
- Accessibility: Trap focus, ARIA labels

**Card (components/ui/Card.tsx):**
- Props: title, children, className
- Styling: Border, shadow, padding, rounded corners
- Responsive: Full width on mobile, constrained on desktop

## Authentication Flow

### Registration Flow

1. User clicks "Login" on homepage
2. Modal opens with login form
3. User clicks "Don't have an account? Register"
4. Form switches to register mode
5. User enters email, password, optional name
6. Client validates inputs
7. On submit, call `AuthContext.register()`
8. AuthContext calls `api.auth.register()`
9. On success: automatically log in (call login with same credentials)
10. On error: Display validation message in modal

### Login Flow

1. User enters email and password
2. Client validates format
3. On submit, call `AuthContext.login()`
4. AuthContext calls `api.auth.login()`
5. API returns `{ user, session_id, expires_at }`
6. Save session_id to cookie via `setSessionId()`
7. Update context with user data and session info
8. Close modal
9. Show dashboard

### Logout Flow

1. User clicks "Logout" button
2. Confirm action (optional: can skip for simplicity)
3. Call `AuthContext.logout()`
4. AuthContext calls `api.auth.logout(sessionId)`
5. Remove session cookie via `removeSessionId()`
6. Clear context state (user = null, sessionId = null)
7. Return to login state (show login button)

### Session Persistence

1. On app load, AuthProvider runs initialization:
   - Call `getSessionId()` to check for cookie
   - If no cookie: Stay logged out
   - If cookie exists: Restore session state
     - Set `sessionId` and `isLoading = true`
     - Optionally validate session (call health endpoint)
     - If valid: User stays logged in
     - If invalid: Clear cookie and stay logged out
2. Session persists across page refreshes via cookie
3. Session expires after 24 hours (API-controlled)

## Error Handling

### API Errors

**401 Unauthorized:**
- Login: "Invalid email or password"
- Session validation: Clear cookie, show login

**400 Bad Request:**
- Registration: "Email already registered" or specific validation error
- Display inline in form

**503 Service Unavailable:**
- LLM: "LLM service not configured. Set APP_ANTHROPIC_API_KEY to enable."
- Show in playground response area

**Network Errors:**
- "Unable to connect to API. Please check that the server is running."
- Display in modal or toast notification

### Client-Side Validation

**Email:**
- Must match email format (use simple regex)
- Show error: "Please enter a valid email address"

**Password:**
- Minimum 12 characters
- Show error: "Password must be at least 12 characters"

**Empty Fields:**
- Show error: "This field is required"

### Error Display Strategy

- **Inline errors:** For form validation (below each field)
- **Modal errors:** For API errors during auth operations
- **Section errors:** For LLM playground errors (in response area)
- **Auto-clear errors:** Clear on user interaction with field

## UI/UX Specifications

### Visual Design

**Color Palette:**
- Primary: `blue-600` (buttons, links)
- Success: `green-600` (success messages)
- Error: `red-600` (error messages, validation)
- Background: `gray-50` (page background)
- Card: `white` (dashboard cards)
- Text: `gray-900` (primary), `gray-600` (secondary)
- Border: `gray-200` (card borders)

**Typography:**
- Font: System font stack (default Next.js)
- Headings: `text-xl` to `text-3xl`, `font-bold`
- Body: `text-base`, `font-normal`
- Labels: `text-sm`, `font-medium`, `text-gray-700`
- Technical data: `font-mono` (session IDs)

**Spacing:**
- Container padding: `p-4` to `p-8`
- Card padding: `p-6`
- Form gaps: `gap-4`
- Section gaps: `gap-6` to `gap-8`

### Responsive Design

**Breakpoints:**
- Mobile: < 768px (single column)
- Tablet: 768px - 1024px (2 columns)
- Desktop: > 1024px (3 columns)

**Mobile Adaptations:**
- Dashboard: Stack cards vertically
- Modal: Full width with padding
- Forms: Full width inputs
- Buttons: Full width on mobile

### Accessibility

**Keyboard Navigation:**
- Tab through all interactive elements
- Escape to close modal
- Enter to submit forms

**ARIA Attributes:**
- `aria-label` on icon buttons
- `aria-describedby` for form errors
- `role="dialog"` on modal
- `aria-hidden` on backdrop

**Screen Readers:**
- Semantic HTML (button, form, input elements)
- Proper labels for all inputs
- Error messages announced
- Loading states announced

### Interactions

**Transitions:**
- Modal: Fade in/out (200ms)
- Button hover: Background color change
- Loading: Spinner animation

**States:**
- Hover: Slightly darker background
- Active: Slightly lighter background
- Disabled: Reduced opacity, no pointer events
- Loading: Spinner, disabled interaction

## Implementation Plan

### Phase 1: Foundation (Core Infrastructure)

1. Install dependencies: `js-cookie`, `@types/js-cookie`
2. Create TypeScript types (`lib/types.ts`)
3. Enhance API client with proper types
4. Create useSessionCookie hook
5. Create AuthContext and AuthProvider
6. Update root layout to include AuthProvider

**Validation:** Can import and use context in components

### Phase 2: UI Components (Building Blocks)

1. Create Button component with variants
2. Create Modal component with backdrop
3. Create Card component
4. Test components in isolation

**Validation:** Components render correctly with different props

### Phase 3: Authentication (Login System)

1. Create LoginModal with form toggle
2. Implement form validation logic
3. Wire up login functionality
4. Wire up register functionality
5. Add error handling and display
6. Create AuthButton component

**Validation:** Can register, login, see errors

### Phase 4: Dashboard (User Interface)

1. Create Dashboard layout component
2. Implement UserProfile component
3. Implement UserStats with countdown timer
4. Implement LLMPlayground component
5. Update homepage to show dashboard when logged in

**Validation:** Dashboard displays user data correctly

### Phase 5: Polish (Final Touches)

1. Add loading states throughout
2. Improve error messages
3. Test session persistence (refresh page)
4. Test logout functionality
5. Responsive design testing
6. Accessibility audit
7. Clean up console warnings

**Validation:** Complete flow works end-to-end

## Testing Strategy

### Manual Testing Checklist

**Authentication:**
- [ ] Register new user with valid data
- [ ] Register with duplicate email (should fail)
- [ ] Register with weak password (should fail)
- [ ] Login with correct credentials
- [ ] Login with wrong credentials (should fail)
- [ ] Logout successfully
- [ ] Session persists after page refresh
- [ ] Session cookie removed after logout

**Dashboard:**
- [ ] User profile shows correct data
- [ ] Session ID is displayed (truncated)
- [ ] Account age calculates correctly
- [ ] Session expiry countdown updates every second
- [ ] All data formats correctly

**LLM Playground:**
- [ ] Can enter prompt
- [ ] Submit button disabled when prompt empty
- [ ] Shows loading state during API call
- [ ] Displays response correctly (if API key configured)
- [ ] Shows 503 message if no API key
- [ ] Clear button works

**UI/UX:**
- [ ] Modal opens and closes smoothly
- [ ] Forms validate inputs
- [ ] Error messages display clearly
- [ ] Loading states show appropriately
- [ ] Responsive on mobile, tablet, desktop
- [ ] Keyboard navigation works
- [ ] No console errors

### Edge Cases

- Empty form submission
- Very long email/password
- Special characters in password
- Session expired (wait 24 hours or manually expire)
- API server not running
- Slow network (test loading states)
- Multiple rapid clicks on submit

## Dependencies

### New Dependencies to Add

```json
{
  "dependencies": {
    "js-cookie": "^3.0.5"
  },
  "devDependencies": {
    "@types/js-cookie": "^3.0.6"
  }
}
```

### Existing Dependencies (No Changes)

- next: ^16.2.6
- react: ^19.2.6
- react-dom: ^19.2.6
- tailwindcss: ^4.0.0
- typescript: ^5.9.0

## Security Considerations

**Note:** This is for local development and testing. Production deployments would need additional security measures.

**Current Approach:**
- Cookies are client-side (not HTTP-only) for simplicity
- Session validation happens on API side
- Passwords sent over HTTP in local dev (use HTTPS in production)
- No CSRF protection (would need in production)

**What's Safe:**
- Passwords hashed with Argon2 on backend
- Session IDs are UUIDs (not guessable)
- API validates all session operations
- No sensitive data in localStorage

**Production Improvements Needed:**
- HTTP-only cookies (requires server-side rendering)
- HTTPS everywhere
- CSRF tokens
- Rate limiting on auth endpoints
- Content Security Policy headers

## Success Criteria

This implementation will be considered successful when:

1. **Functional:**
   - Users can register, login, and logout
   - Sessions persist across page refreshes
   - Dashboard displays all user data correctly
   - LLM playground works (with API key) or shows helpful message (without)

2. **User Experience:**
   - Smooth, intuitive interactions
   - Clear error messages
   - Responsive design works on all screen sizes
   - No confusing states or broken flows

3. **Code Quality:**
   - Type-safe TypeScript throughout
   - Reusable components with clear interfaces
   - No prop drilling (context solves this)
   - Clean separation of concerns
   - Follows React best practices

4. **Educational:**
   - Demonstrates React Context pattern
   - Shows custom hooks usage
   - Illustrates API integration
   - Serves as learning example

## Future Enhancements (Out of Scope)

- Email verification
- Password reset flow
- User profile editing
- Account deletion
- Advanced LLM features (streaming, history)
- Real-time session validation
- Multiple concurrent sessions
- Remember me checkbox
- Social login (OAuth)
- Two-factor authentication

## Conclusion

This design provides a complete, production-quality learning example of building an authenticated web application with React, Next.js, and a RESTful API. The implementation prioritizes clarity, maintainability, and educational value while delivering a fully functional authentication and dashboard system.

The architecture using React Context and custom hooks represents modern React best practices and provides a solid foundation for future enhancements. The modal-based login flow offers an excellent user experience, while the comprehensive dashboard demonstrates real-world data display and interaction patterns.

By following this specification, developers will create a working, testable authentication system that can be extended and adapted for production use cases with appropriate security hardening.
