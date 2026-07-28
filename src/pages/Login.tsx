import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import { Mail, Lock, ShieldAlert, CheckCircle, ArrowLeft, KeyRound, Eye, EyeOff } from 'lucide-react';
import logoBlack from '../assets/logo_black.png';
import './Login.css';

const Login: React.FC = () => {
  const { login } = useAuth();
  const navigate = useNavigate();

  // Mode: 'login' | 'forgot' | 'reset'
  const [mode, setMode] = useState<'login' | 'forgot' | 'reset'>('login');
  
  // Password Visibility toggles
  const [showPassword, setShowPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  
  // Login Inputs
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  
  // Forgot / Reset Inputs
  const [resetEmail, setResetEmail] = useState('');
  const [resetToken, setResetToken] = useState('');
  const [newPassword, setNewPassword] = useState('');

  // Status flags
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const switchMode = (newMode: 'login' | 'forgot' | 'reset') => {
    setMode(newMode);
    setError(null);
    setSuccess(null);
  };

  // Sign In Handler
  const handleLoginSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError('Please fill in both email and password.');
      return;
    }

    setError(null);
    setLoading(true);
    try {
      await login(email, password);
      // Main dashboard routing '/' will handle correct dashboard redirect
      navigate('/');
    } catch (err: any) {
      console.error(err);
      setError(err.response?.data?.message || 'Login failed. Please verify credentials.');
    } finally {
      setLoading(false);
    }
  };

  // Request Reset Token Handler
  const handleForgotPasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!resetEmail) {
      setError('Please enter your email address.');
      return;
    }

    setError(null);
    setSuccess(null);
    setLoading(true);
    try {
      const res = await api.post('/auth/forgot-password', { email: resetEmail });
      setSuccess(res.data.message || 'Password reset token generated.');
      
      // Auto-populate token if returned in response (useful for local dev/testing without active SMTP mailers)
      if (res.data.resetToken) {
        setResetToken(res.data.resetToken);
        // Switch to reset mode after a brief moment
        setTimeout(() => {
          switchMode('reset');
        }, 2000);
      }
    } catch (err: any) {
      console.error(err);
      setError(err.response?.data?.message || 'Failed to request reset token. Try again.');
    } finally {
      setLoading(false);
    }
  };

  // Submit Password Reset Handler
  const handleResetPasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!resetToken || !newPassword) {
      setError('Please fill in both the reset token and new password.');
      return;
    }

    if (newPassword.length < 6) {
      setError('Password must be at least 6 characters long.');
      return;
    }

    setError(null);
    setSuccess(null);
    setLoading(true);
    try {
      const res = await api.post(`/auth/reset-password/${resetToken}`, { password: newPassword });
      setSuccess(res.data.message || 'Password reset successful!');
      
      // Redirect back to login tab after success
      setTimeout(() => {
        switchMode('login');
        setEmail(resetEmail); // Pre-fill email
        setNewPassword('');
        setResetToken('');
      }, 3000);
    } catch (err: any) {
      console.error(err);
      setError(err.response?.data?.message || 'Failed to reset password. Check if token expired.');
    } finally {
      setLoading(false);
    }
  };


  return (
    <div className="login-page-container">
      <div className="login-glass-box glass-card fade-in">
        {/* Brand identity */}
        <div className="login-brand">
          <img src={logoBlack} alt="Velocity Home logo" className="login-logo-img" />
          <h2 className="login-title">Attendance Hub</h2>
          <p className="login-desc">
            {mode === 'login' && 'Sign in to access your dashboard'}
            {mode === 'forgot' && 'Reset your corporate login credentials'}
            {mode === 'reset' && 'Create your new system password'}
          </p>
        </div>

        {error && (
          <div className="login-alert login-alert-error">
            <ShieldAlert size={18} />
            <span>{error}</span>
          </div>
        )}

        {success && (
          <div className="login-alert login-alert-success">
            <CheckCircle size={18} />
            <span>{success}</span>
          </div>
        )}

        {/* 1. Login View */}
        {mode === 'login' && (
          <form className="login-form" onSubmit={handleLoginSubmit}>
            <div className="form-group">
              <label className="form-label">Email Address</label>
              <div className="input-with-icon">
                <Mail className="input-icon" size={18} />
                <input 
                  type="email" 
                  name="attendance_email"
                  className="form-input" 
                  placeholder="Email" 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  autoComplete="off"
                  required
                />
              </div>
            </div>

            <div className="form-group">
              <div className="label-row">
                <label className="form-label">Password</label>
                <button 
                  type="button" 
                  className="forgot-pwd-link"
                  onClick={() => switchMode('forgot')}
                >
                  Forgot Password?
                </button>
              </div>
              <div className="input-with-icon">
                <Lock className="input-icon" size={18} />
                <input 
                  type={showPassword ? "text" : "password"} 
                  name="attendance_password"
                  className="form-input has-password-toggle" 
                  placeholder="Password" 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="new-password"
                  required
                />
                <button 
                  type="button" 
                  className="password-toggle-btn"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? "Hide password" : "Show password"}
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <button type="submit" className="btn btn-primary login-submit-btn" disabled={loading}>
              {loading ? 'Authenticating...' : 'Sign In'}
            </button>
          </form>
        )}

        {/* 2. Forgot Password View */}
        {mode === 'forgot' && (
          <form className="login-form" onSubmit={handleForgotPasswordSubmit}>
            <div className="form-group">
              <label className="form-label">Registered Email</label>
              <div className="input-with-icon">
                <Mail className="input-icon" size={18} />
                <input 
                  type="email" 
                  className="form-input" 
                  placeholder="Email" 
                  value={resetEmail}
                  onChange={(e) => setResetEmail(e.target.value)}
                  required
                />
              </div>
            </div>

            <button type="submit" className="btn btn-primary login-submit-btn" disabled={loading}>
              {loading ? 'Processing...' : 'Send Reset Link'}
            </button>

            <div className="login-navigation-links">
              <button type="button" className="nav-back-btn" onClick={() => switchMode('login')}>
                <ArrowLeft size={16} />
                <span>Back to Sign In</span>
              </button>
              <button type="button" className="nav-token-btn" onClick={() => switchMode('reset')}>
                <span>Have a Reset Token?</span>
              </button>
            </div>
          </form>
        )}

        {/* 3. Reset Password View */}
        {mode === 'reset' && (
          <form className="login-form" onSubmit={handleResetPasswordSubmit}>
            <div className="form-group">
              <label className="form-label">Reset Token</label>
              <div className="input-with-icon">
                <KeyRound className="input-icon" size={18} />
                <input 
                  type="text" 
                  className="form-input" 
                  placeholder="Paste token received in email" 
                  value={resetToken}
                  onChange={(e) => setResetToken(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">New Password</label>
              <div className="input-with-icon">
                <Lock className="input-icon" size={18} />
                <input 
                  type={showNewPassword ? "text" : "password"} 
                  className="form-input has-password-toggle" 
                  placeholder="Password" 
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  required
                />
                <button 
                  type="button" 
                  className="password-toggle-btn"
                  onClick={() => setShowNewPassword(!showNewPassword)}
                  aria-label={showNewPassword ? "Hide password" : "Show password"}
                >
                  {showNewPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <button type="submit" className="btn btn-primary login-submit-btn" disabled={loading}>
              {loading ? 'Resetting Password...' : 'Save New Password'}
            </button>

            <button type="button" className="nav-back-btn centered-nav-btn" onClick={() => switchMode('login')}>
              <ArrowLeft size={16} />
              <span>Back to Sign In</span>
            </button>
          </form>
        )}
      </div>
    </div>
  );
};

export default Login;
