import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import { Mail, Lock, ShieldAlert, CheckCircle, ArrowLeft, KeyRound, Eye, EyeOff, User } from 'lucide-react';
import logoBlack from '../assets/logo_black.png';
import './Login.css';

const Login: React.FC = () => {
  const { login } = useAuth();
  const navigate = useNavigate();

  // Mode: 'login' | 'register' | 'forgot' | 'reset' | 'setup'
  const [mode, setMode] = useState<'login' | 'register' | 'forgot' | 'reset' | 'setup'>('login');
  
  // Password Visibility toggles
  const [showPassword, setShowPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showSetupPassword, setShowSetupPassword] = useState(false);
  
  // Login Inputs
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  // Register Inputs
  const [regName, setRegName] = useState('');
  const [regEmail, setRegEmail] = useState('');
  const [regPassword, setRegPassword] = useState('');
  const [regDepartment, setRegDepartment] = useState('');
  const [regLocation, setRegLocation] = useState('');
  
  // Forgot / Reset Inputs
  const [resetEmail, setResetEmail] = useState('');
  const [resetToken, setResetToken] = useState('');
  const [newPassword, setNewPassword] = useState('');

  // Setup Inputs
  const [setupName, setSetupName] = useState('');
  const [setupEmail, setSetupEmail] = useState('');
  const [setupPassword, setSetupPassword] = useState('');
  const [setupPasskey, setSetupPasskey] = useState('');

  // Status flags
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const switchMode = (newMode: 'login' | 'register' | 'forgot' | 'reset' | 'setup') => {
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

  // Register Handler
  const handleRegisterSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!regName || !regEmail || !regPassword || !regDepartment || !regLocation) {
      setError('Please fill in all registration fields.');
      return;
    }
    if (regPassword.length < 6) {
      setError('Password must be at least 6 characters long.');
      return;
    }

    setError(null);
    setLoading(true);
    try {
      const res = await api.post('/auth/register', {
        name: regName,
        email: regEmail,
        password: regPassword,
        department: regDepartment,
        location: regLocation
      });
      setSuccess(res.data.message || 'Registration successful. Pending admin approval.');
      // Switch back to login after 3 seconds
      setTimeout(() => switchMode('login'), 3000);
    } catch (err: any) {
      console.error(err);
      setError(err.response?.data?.message || 'Registration failed.');
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

  // Submit Super Admin Setup Handler
  const handleSetupSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!setupName || !setupEmail || !setupPassword || !setupPasskey) {
      setError('Please fill in all setup fields.');
      return;
    }

    if (setupPassword.length < 6) {
      setError('Password must be at least 6 characters long.');
      return;
    }

    setError(null);
    setSuccess(null);
    setLoading(true);
    try {
      const res = await api.post('/admin/setup-super-admin', {
        name: setupName,
        email: setupEmail,
        password: setupPassword,
        passkey: setupPasskey
      });
      setSuccess(res.data.message || 'Super Admin created successfully!');
      
      // Auto-populate credentials and log in or go to sign-in page
      setTimeout(() => {
        switchMode('login');
        setEmail(setupEmail);
        setPassword(setupPassword);
        
        // Reset setup inputs
        setSetupName('');
        setSetupEmail('');
        setSetupPassword('');
        setSetupPasskey('');
      }, 3000);
    } catch (err: any) {
      console.error(err);
      setError(err.response?.data?.message || 'Super Admin setup failed. Verify passkey and email details.');
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
          {mode !== 'login' && (
            <p className="login-desc">
              {mode === 'register' && 'Register a new employee account'}
              {mode === 'forgot' && 'Reset your corporate login credentials'}
              {mode === 'reset' && 'Create your new system password'}
              {mode === 'setup' && 'Setup first Root Administrator (Super Admin)'}
            </p>
          )}
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

            <div className="login-setup-prompt">
              <span>Don't have an account?</span>
              <button 
                type="button" 
                className="setup-admin-link-btn"
                onClick={() => switchMode('register')}
              >
                Sign Up
              </button>
            </div>
            <div className="login-setup-prompt" style={{ marginTop: '0.5rem' }}>
              <span>New database setup?</span>
              <button 
                type="button" 
                className="setup-admin-link-btn"
                onClick={() => switchMode('setup')}
              >
                Setup Super Admin
              </button>
            </div>
          </form>
        )}

        {/* 1.5. Register View */}
        {mode === 'register' && (
          <form className="login-form" onSubmit={handleRegisterSubmit}>
            <div className="form-group">
              <label className="form-label">Full Name</label>
              <div className="input-with-icon">
                <User className="input-icon" size={18} />
                <input 
                  type="text" 
                  className="form-input" 
                  placeholder="John Doe" 
                  value={regName}
                  onChange={(e) => setRegName(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Email Address</label>
              <div className="input-with-icon">
                <Mail className="input-icon" size={18} />
                <input 
                  type="email" 
                  className="form-input" 
                  placeholder="Email" 
                  value={regEmail}
                  onChange={(e) => setRegEmail(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Password</label>
              <div className="input-with-icon">
                <Lock className="input-icon" size={18} />
                <input 
                  type={showSetupPassword ? "text" : "password"} 
                  className="form-input has-password-toggle" 
                  placeholder="Min. 6 characters" 
                  value={regPassword}
                  onChange={(e) => setRegPassword(e.target.value)}
                  required
                />
                <button 
                  type="button" 
                  className="password-toggle-btn"
                  onClick={() => setShowSetupPassword(!showSetupPassword)}
                >
                  {showSetupPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Department</label>
              <div className="input-with-icon">
                <input 
                  type="text" 
                  className="form-input" 
                  style={{ paddingLeft: '1rem' }}
                  placeholder="e.g. Engineering" 
                  value={regDepartment}
                  onChange={(e) => setRegDepartment(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Location</label>
              <div className="input-with-icon">
                <input 
                  type="text" 
                  className="form-input"
                  style={{ paddingLeft: '1rem' }}
                  placeholder="e.g. Kerala" 
                  value={regLocation}
                  onChange={(e) => setRegLocation(e.target.value)}
                  required
                />
              </div>
            </div>

            <button type="submit" className="btn btn-primary login-submit-btn" disabled={loading}>
              {loading ? 'Registering...' : 'Sign Up'}
            </button>

            <button type="button" className="nav-back-btn centered-nav-btn" onClick={() => switchMode('login')}>
              <ArrowLeft size={16} />
              <span>Back to Sign In</span>
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

        {/* 4. Super Admin Setup View */}
        {mode === 'setup' && (
          <form className="login-form" onSubmit={handleSetupSubmit}>
            <div className="form-group">
              <label className="form-label">Super Admin Full Name</label>
              <div className="input-with-icon">
                <User className="input-icon" size={18} />
                <input 
                  type="text" 
                  className="form-input" 
                  placeholder="e.g. Administrator" 
                  value={setupName}
                  onChange={(e) => setSetupName(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Admin Email Address</label>
              <div className="input-with-icon">
                <Mail className="input-icon" size={18} />
                <input 
                  type="email" 
                  className="form-input" 
                  placeholder="admin@company.com" 
                  value={setupEmail}
                  onChange={(e) => setSetupEmail(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Password</label>
              <div className="input-with-icon">
                <Lock className="input-icon" size={18} />
                <input 
                  type={showSetupPassword ? "text" : "password"} 
                  className="form-input has-password-toggle" 
                  placeholder="Min. 6 characters" 
                  value={setupPassword}
                  onChange={(e) => setSetupPassword(e.target.value)}
                  required
                />
                <button 
                  type="button" 
                  className="password-toggle-btn"
                  onClick={() => setShowSetupPassword(!showSetupPassword)}
                  aria-label={showSetupPassword ? "Hide password" : "Show password"}
                >
                  {showSetupPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Secret Backend Passkey</label>
              <div className="input-with-icon">
                <KeyRound className="input-icon" size={18} />
                <input 
                  type="password" 
                  className="form-input" 
                  placeholder="Enter system setup passkey" 
                  value={setupPasskey}
                  onChange={(e) => setSetupPasskey(e.target.value)}
                  required
                />
              </div>
            </div>

            <button type="submit" className="btn btn-primary login-submit-btn" disabled={loading}>
              {loading ? 'Configuring System...' : 'Configure Super Admin'}
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
