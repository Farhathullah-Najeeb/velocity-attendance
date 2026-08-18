import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import type { ILeave, ILeaveBalance, LeaveType } from '../types';
import { 
  Send, 
  History, 
  CheckCircle, 
  XCircle, 
  PlusCircle
} from 'lucide-react';
import './LeaveManagement.css';

const LeaveManagement: React.FC = () => {
  const { user } = useAuth();
  
  // States
  const [leaves, setLeaves] = useState<ILeave[]>([]);
  const [balance, setBalance] = useState<ILeaveBalance | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitLoading, setSubmitLoading] = useState(false);
  
  // Form states
  const [type, setType] = useState<LeaveType>('CASUAL');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [reason, setReason] = useState('');
  
  // UI states
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const [quotaError, setQuotaError] = useState<{
    location: string;
    monthlyQuota: number;
    monthlyUsed: number;
    requestedDuration: number;
  } | null>(null);
  const [showApplyForm, setShowApplyForm] = useState(false);

  // Fetch leave list and balance
  const fetchData = async () => {
    if (!user) return;
    setLoading(true);
    try {
      const [leavesRes, balanceRes] = await Promise.all([
        api.get<ILeave[]>('/leaves'),
        api.get<ILeaveBalance>(`/leaves/balance/${user._id}`)
      ]);
      setLeaves(leavesRes.data);
      setBalance(balanceRes.data);
    } catch (err) {
      console.error('Error fetching leave details:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user) {
      fetchData();
    }
  }, [user]);

  // Form Duration Calculator
  const getDuration = () => {
    if (!fromDate || !toDate) return 0;
    const start = new Date(fromDate);
    const end = new Date(toDate);
    if (isNaN(start.getTime()) || isNaN(end.getTime()) || start > end) return 0;
    
    const diffTime = Math.abs(end.getTime() - start.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
  };

  // Form Submit Handler
  const handleApplyLeave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!type || !fromDate || !toDate || !reason.trim()) {
      setMessage({ text: 'Please fill in all details.', type: 'error' });
      return;
    }

    const duration = getDuration();
    if (duration <= 0) {
      setMessage({ text: 'End date must be on or after start date.', type: 'error' });
      return;
    }

    // Front-end Compensatory off balance validation
    if (type === 'COMPENSATORY' && balance) {
      const availableComp = balance.balances.COMPENSATORY.remaining;
      if (availableComp < duration) {
        setMessage({ 
          text: `Insufficient Comp-Off credits. You requested ${duration} days, but only have ${availableComp} available.`, 
          type: 'error' 
        });
        return;
      }
    }

    setSubmitLoading(true);
    setMessage(null);
    setQuotaError(null);
    try {
      const res = await api.post('/leaves/apply', {
        type,
        fromDate,
        toDate,
        reason: reason.trim()
      });
      
      setMessage({ text: res.data.message || 'Leave application submitted successfully!', type: 'success' });
      // Clear form
      setFromDate('');
      setToDate('');
      setReason('');
      setShowApplyForm(false);
      
      // Refresh balance and leave records
      fetchData();
    } catch (err: any) {
      console.error('Apply leave error:', err);
      if (err.response?.status === 400 && err.response?.data?.monthlyQuota !== undefined) {
        setQuotaError(err.response.data);
        setMessage({ text: err.response.data.message || 'Leave quota exceeded.', type: 'error' });
      } else {
        setMessage({
          text: err.response?.data?.message || 'Failed to submit leave. Please verify date parameters.',
          type: 'error'
        });
      }
    } finally {
      setSubmitLoading(false);
    }
  };

  const [cancelLoading, setCancelLoading] = useState<string | null>(null);

  const handleCancelLeave = async (id: string) => {
    if (!window.confirm('Are you sure you want to cancel this leave application?')) return;
    
    setCancelLoading(id);
    setMessage(null);
    try {
      const res = await api.patch(`/leaves/${id}/cancel`);
      setMessage({ 
        text: res.data.message || 'Leave request successfully withdrawn.', 
        type: 'success' 
      });
      fetchData();
    } catch (err: any) {
      console.error('Cancel leave error:', err);
      setMessage({
        text: err.response?.data?.message || 'Failed to withdraw leave request.',
        type: 'error'
      });
    } finally {
      setCancelLoading(null);
    }
  };

  // Format date helper
  const formatDate = (dateStr: string) => {
    const d = new Date(dateStr);
    return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
  };

  // Calculate day difference for history records
  const calculateDays = (from: string, to: string) => {
    const start = new Date(from);
    const end = new Date(to);
    const diffTime = Math.abs(end.getTime() - start.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
  };

  return (
    <div className="leaves-container fade-in">
      <header className="leaves-header">
        <div>
          <h1>Leave Management</h1>
          <p className="subtitle">Apply for time off and review your previous requests.</p>
        </div>
        <button 
          className="btn btn-primary"
          onClick={() => {
            setShowApplyForm(!showApplyForm);
            setMessage(null);
            setQuotaError(null);
          }}
        >
          <PlusCircle size={20} />
          {showApplyForm ? 'View Leave Logs' : 'Apply for Leave'}
        </button>
      </header>

      {message && (
        <div className={`leaves-alert alert-${message.type === 'success' ? 'success' : 'danger'}`}>
          {message.type === 'success' ? <CheckCircle size={20} /> : <XCircle size={20} />}
          <span>{message.text}</span>
        </div>
      )}

      {quotaError && (
        <div className="leaves-alert alert-danger" style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', padding: '1rem', marginTop: '0' }}>
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '0.5rem', fontWeight: 'bold' }}>
            <XCircle size={20} style={{ marginRight: '8px' }} />
            Policy Restriction: Location Leave Quota Exceeded
          </div>
          <p style={{ margin: '0 0 0.5rem 28px', fontSize: '0.9rem' }}>
            Your designated location (<strong>{quotaError.location}</strong>) limits employees to <strong>{quotaError.monthlyQuota} day(s)</strong> of paid leave per month.
          </p>
          <ul style={{ margin: '0 0 0 28px', fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
            <li>Used this month: {quotaError.monthlyUsed} day(s)</li>
            <li>Requested duration: {quotaError.requestedDuration} day(s)</li>
          </ul>
        </div>
      )}

      {/* Leave Balances Header Cards */}
      {balance && !showApplyForm && (
        <div className="balance-cards-grid">
          <div className="balance-card glass-card border-purple">
            <span className="balance-label">Casual Leaves</span>
            <h2 className="balance-num">{balance.balances.CASUAL.remaining}</h2>
            <span className="balance-sub">Taken: {balance.balances.CASUAL.taken} / {balance.balances.CASUAL.allowed} Days</span>
          </div>
          
          <div className="balance-card glass-card border-cyan">
            <span className="balance-label">Sick Leaves</span>
            <h2 className="balance-num">{balance.balances.SICK.remaining}</h2>
            <span className="balance-sub">Taken: {balance.balances.SICK.taken} / {balance.balances.SICK.allowed} Days</span>
          </div>

          <div className="balance-card glass-card border-green">
            <span className="balance-label">Compensatory Offs</span>
            <h2 className="balance-num">{balance.balances.COMPENSATORY.remaining}</h2>
            <span className="balance-sub">Earned: {balance.balances.COMPENSATORY.earned} | Used: {balance.balances.COMPENSATORY.used}</span>
          </div>

          <div className="balance-card glass-card border-gray">
            <span className="balance-label">Other Leaves</span>
            <h2 className="balance-num">{balance.balances.OTHER.taken}</h2>
            <span className="balance-sub">Total Taken (Unregulated)</span>
          </div>
        </div>
      )}

      {showApplyForm ? (
        /* Leave Application Form */
        <div className="apply-form-section glass-card fade-in">
          <div className="form-header">
            <Send className="form-header-icon" />
            <h3>Request Time Off</h3>
          </div>
          
          <form className="apply-leave-form" onSubmit={handleApplyLeave}>
            <div className="form-row-two">
              <div className="form-group">
                <label className="form-label">Leave Type</label>
                <select 
                  className="form-select" 
                  value={type}
                  onChange={(e) => setType(e.target.value as LeaveType)}
                  required
                >
                  <option value="CASUAL">Casual Leave</option>
                  <option value="SICK">Sick Leave</option>
                  <option value="COMPENSATORY">Compensatory Off (Comp-Off)</option>
                  <option value="OTHER">Other Leave (Special)</option>
                </select>
              </div>

              <div className="form-duration-display">
                <span className="dur-label">Calculated Duration</span>
                <span className="dur-days">{getDuration()} Days</span>
              </div>
            </div>

            <div className="form-row-two">
              <div className="form-group">
                <label className="form-label">Start Date</label>
                <input 
                  type="date" 
                  className="form-input" 
                  value={fromDate}
                  onChange={(e) => setFromDate(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">End Date</label>
                <input 
                  type="date" 
                  className={`form-input ${fromDate && toDate && fromDate > toDate ? 'input-error' : ''}`} 
                  value={toDate}
                  onChange={(e) => setToDate(e.target.value)}
                  required
                />
                {fromDate && toDate && fromDate > toDate && (
                  <span className="error-text-inline">End date cannot be earlier than start date.</span>
                )}
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Reason for Request</label>
              <textarea 
                className="form-textarea" 
                placeholder="Please state the purpose of your time off request..."
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                required
              />
            </div>

            <div className="form-actions">
              <button 
                type="button" 
                className="btn btn-secondary"
                onClick={() => setShowApplyForm(false)}
              >
                Cancel
              </button>
              <button 
                type="submit" 
                className="btn btn-primary"
                disabled={submitLoading}
              >
                {submitLoading ? 'Submitting request...' : 'Submit Application'}
              </button>
            </div>
          </form>
        </div>
      ) : (
        /* Leave History List */
        <div className="leave-history-section glass-card">
          <div className="history-header">
            <History size={20} className="accent-color-icon" />
            <h3>Your Leave Log</h3>
          </div>

          {loading ? (
            <p className="text-muted">Loading leave logs...</p>
          ) : leaves.length > 0 ? (
            <div className="leave-logs-container">
              {/* Desktop Table View */}
              <div className="table-responsive hide-on-mobile">
                <table className="leave-table">
                  <thead>
                    <tr>
                      <th>Leave Type</th>
                      <th>Date Duration</th>
                      <th>Days</th>
                      <th>Reason</th>
                      <th>Status</th>
                      <th>Remarks</th>
                      <th className="center-cell">Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {leaves.map((leave) => {
                      const days = calculateDays(leave.fromDate, leave.toDate);
                      return (
                        <tr key={leave._id}>
                          <td>
                            <span className={`leave-type-indicator type-${leave.type.toLowerCase()}`}>
                              {leave.type}
                            </span>
                          </td>
                          <td>
                            <strong>{formatDate(leave.fromDate)}</strong> to <strong>{formatDate(leave.toDate)}</strong>
                          </td>
                          <td className="center-cell">{days}</td>
                          <td className="reason-cell">{leave.reason}</td>
                          <td>
                            <span className={`badge badge-${
                              leave.status === 'APPROVED' ? 'success' : 
                              leave.status === 'REJECTED' ? 'danger' : 'warning'
                            }`}>
                              {leave.status}
                            </span>
                          </td>
                          <td className="remarks-cell">
                            {leave.remarks ? (
                              <span className="remark-text">"{leave.remarks}"</span>
                            ) : (
                              <span className="text-muted italic">—</span>
                            )}
                          </td>
                          <td className="center-cell">
                            {leave.status === 'PENDING' ? (
                              <button 
                                type="button"
                                className="btn-cancel-leave"
                                onClick={() => handleCancelLeave(leave._id)}
                                disabled={cancelLoading === leave._id}
                              >
                                {cancelLoading === leave._id ? 'Cancelling...' : 'Cancel'}
                              </button>
                            ) : (
                              <span className="text-muted italic">—</span>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>

              {/* Mobile Card List View */}
              <div className="mobile-cards-list show-on-mobile">
                {leaves.map((leave) => {
                  const days = calculateDays(leave.fromDate, leave.toDate);
                  return (
                    <div key={leave._id} className="mobile-log-card glass-card">
                      <div className="card-row-header">
                        <span className={`leave-type-indicator type-${leave.type.toLowerCase()}`}>
                          {leave.type}
                        </span>
                        <span className={`badge badge-${
                          leave.status === 'APPROVED' ? 'success' : 
                          leave.status === 'REJECTED' ? 'danger' : 'warning'
                        }`}>
                          {leave.status}
                        </span>
                      </div>
                      
                      <div className="card-row-details">
                        <div className="detail-item">
                          <span className="detail-lbl">Duration</span>
                          <span className="detail-val">
                            <strong>{formatDate(leave.fromDate)}</strong> to <strong>{formatDate(leave.toDate)}</strong>
                            <span className="days-cnt"> ({days} {days === 1 ? 'day' : 'days'})</span>
                          </span>
                        </div>
                        
                        <div className="detail-item">
                          <span className="detail-lbl">Reason</span>
                          <span className="detail-val">{leave.reason}</span>
                        </div>
                        
                        {leave.remarks && (
                          <div className="detail-item remark-box">
                            <span className="detail-lbl">Remarks</span>
                            <span className="detail-val italic">"{leave.remarks}"</span>
                          </div>
                        )}
                      </div>
                      {leave.status === 'PENDING' && (
                        <div className="card-row-actions">
                          <button 
                            type="button"
                            className="btn btn-danger btn-cancel-mobile flex-1"
                            onClick={() => handleCancelLeave(leave._id)}
                            disabled={cancelLoading === leave._id}
                          >
                            {cancelLoading === leave._id ? 'Cancelling...' : 'Cancel Request'}
                          </button>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          ) : (
            <p className="text-muted padding-2rem text-center">No leave applications recorded yet.</p>
          )}
        </div>
      )}
    </div>
  );
};

export default LeaveManagement;
