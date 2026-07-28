import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import type { ISettings } from '../types';
import { 
  Mail, 
  Briefcase, 
  Shield, 
  Clock, 
  Coffee, 
  AlertCircle,
  Copy,
  Check,
  KeyRound,
  CheckCircle,
  XCircle
} from 'lucide-react';
import './Profile.css';

const Profile: React.FC = () => {
  const { user } = useAuth();
  const [settings, setSettings] = useState<ISettings | null>(null);
  const [loadingSettings, setLoadingSettings] = useState(true);
  const [copied, setCopied] = useState(false);

  // Change Password form states
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [pwdLoading, setPwdLoading] = useState(false);
  const [pwdMessage, setPwdMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const handleCopyEmail = () => {
    if (!user?.email) return;
    navigator.clipboard.writeText(user.email);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  // Fetch Office Settings
  const fetchSettings = async () => {
    setLoadingSettings(true);
    try {
      const res = await api.get<ISettings>('/settings');
      setSettings(res.data);
    } catch (err) {
      console.error('Error fetching settings:', err);
    } finally {
      setLoadingSettings(false);
    }
  };

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentPassword || !newPassword) {
      setPwdMessage({ text: 'Please fill in both fields.', type: 'error' });
      return;
    }
    if (newPassword.length < 6) {
      setPwdMessage({ text: 'New password must be at least 6 characters long.', type: 'error' });
      return;
    }

    setPwdLoading(true);
    setPwdMessage(null);
    try {
      const res = await api.post('/auth/change-password', {
        currentPassword,
        newPassword
      });
      setPwdMessage({ 
        text: res.data.message || 'Password changed successfully.', 
        type: 'success' 
      });
      setCurrentPassword('');
      setNewPassword('');
    } catch (err: any) {
      console.error('Change password error:', err);
      setPwdMessage({
        text: err.response?.data?.message || 'Failed to change password. Please verify current password.',
        type: 'error'
      });
    } finally {
      setPwdLoading(false);
    }
  };

  const formatTime12h = (timeStr?: string) => {
    if (!timeStr) return '—';
    const [hoursStr, minutesStr] = timeStr.split(':');
    const hours = parseInt(hoursStr, 10);
    if (isNaN(hours)) return timeStr;
    const ampm = hours >= 12 ? 'PM' : 'AM';
    const displayHours = hours % 12 || 12;
    const minutes = minutesStr ? minutesStr.padStart(2, '0') : '00';
    return `${displayHours}:${minutes} ${ampm}`;
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  if (!user) return null;

  return (
    <div className="profile-container fade-in">
      <header className="profile-header-title">
        <h1>My Profile</h1>
        <p className="subtitle">Manage your personal credentials and view official work policy definitions.</p>
      </header>

      <div className="profile-grid">
        {/* Left Column Group */}
        <div className="profile-left-col">
          {/* Profile Card */}
          <section className="profile-info-card glass-card">
            <div className="avatar-large-container">
              <div className="avatar-large">
                {user.name.charAt(0).toUpperCase()}
              </div>
              <h3>{user.name}</h3>
              <span className="profile-role-badge">{user.role}</span>
            </div>

            <div className="profile-details-list">
              <div className="profile-detail-row">
                <Mail size={18} className="detail-icon" />
                <div className="detail-meta flex-grow-1">
                  <span className="detail-lbl">Email Address</span>
                  <div className="detail-val-copy-row">
                    <strong className="detail-val">{user.email}</strong>
                    <button 
                      type="button" 
                      className={`btn-copy-inline ${copied ? 'copied' : ''}`}
                      onClick={handleCopyEmail}
                      title="Copy email to clipboard"
                    >
                      {copied ? <Check size={14} className="copied-check" /> : <Copy size={14} />}
                    </button>
                  </div>
                </div>
              </div>

              <div className="profile-detail-row">
                <Briefcase size={18} className="detail-icon" />
                <div className="detail-meta">
                  <span className="detail-lbl">Department</span>
                  <strong className="detail-val">{user.department || 'EMPLOYEE'}</strong>
                </div>
              </div>

              <div className="profile-detail-row">
                <Shield size={18} className="detail-icon" />
                <div className="detail-meta">
                  <span className="detail-lbl">System Authorization</span>
                  <strong className="detail-val">{user.role === 'EMPLOYEE' ? 'Regular Employee' : 'Administrator'}</strong>
                </div>
              </div>
            </div>
          </section>

          {/* Change Password Card */}
          <section className="change-password-card glass-card">
            <div className="card-header-icon">
              <KeyRound size={20} className="accent-color-icon" />
              <h3>Change Password</h3>
            </div>

            <form onSubmit={handleChangePassword} className="change-password-form">
              {pwdMessage && (
                <div className={`pwd-alert alert-${pwdMessage.type === 'success' ? 'success' : 'danger'}`}>
                  {pwdMessage.type === 'success' ? <CheckCircle size={16} /> : <XCircle size={16} />}
                  <span>{pwdMessage.text}</span>
                </div>
              )}

              <div className="form-group">
                <label className="form-label">Current Password</label>
                <input 
                  type="password" 
                  className="form-input" 
                  placeholder="Current password"
                  value={currentPassword}
                  onChange={(e) => setCurrentPassword(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">New Password</label>
                <input 
                  type="password" 
                  className="form-input" 
                  placeholder="New password (min. 6 chars)"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  required
                />
              </div>

              <button type="submit" className="btn btn-primary w-full" disabled={pwdLoading}>
                {pwdLoading ? 'Updating password...' : 'Update Password'}
              </button>
            </form>
          </section>
        </div>

        {/* Work Policies Settings card */}
        <section className="policy-settings-card glass-card">
          <div className="card-header-icon">
            <Clock size={24} className="accent-color-icon" />
            <h3>Standard Office Policies</h3>
          </div>

          <p className="policy-intro">
            These limits are configured by the administration and determine late-arrival and early-checkout exceptions.
          </p>

          {loadingSettings ? (
            <p className="text-muted">Loading policy parameters...</p>
          ) : settings ? (
            <div className="policy-grid">
              <div className="policy-item-box">
                <Clock className="policy-icon-blue" size={24} />
                <div className="policy-item-details">
                  <span>Shift Start Time</span>
                  <strong>{formatTime12h(settings.officeStartTime)}</strong>
                </div>
              </div>

              <div className="policy-item-box">
                <Coffee className="policy-icon-orange" size={24} />
                <div className="policy-item-details">
                  <span>Shift End Time</span>
                  <strong>{formatTime12h(settings.officeEndTime)}</strong>
                </div>
              </div>

              <div className="policy-item-box">
                <AlertCircle className="policy-icon-purple" size={24} />
                <div className="policy-item-details">
                  <span>Grace Period</span>
                  <strong>{settings.gracePeriod} Minutes</strong>
                </div>
              </div>
            </div>
          ) : (
            <p className="text-muted">Failed to retrieve policy settings.</p>
          )}

          <div className="policy-alert-warning">
            <AlertCircle size={16} />
            <span>Arriving after Shift Start + Grace Period automatically marks your attendance as Late. Leaving before Shift End marks it as Early Checkout, requesting administrative approval.</span>
          </div>
        </section>
      </div>
    </div>
  );
};

export default Profile;
