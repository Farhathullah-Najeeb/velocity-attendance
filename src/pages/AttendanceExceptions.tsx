import React, { useState, useEffect } from 'react';
import api from '../services/api';
import type { IAttendance } from '../types';
import { 
  CheckCircle, 
  XCircle, 
  MapPin, 
  Calendar,
  AlertTriangle,
  Check,
  X
} from 'lucide-react';
import './AttendanceExceptions.css';

const AttendanceExceptions: React.FC = () => {
  const [exceptions, setExceptions] = useState<IAttendance[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Modal states
  const [selectedException, setSelectedException] = useState<IAttendance | null>(null);
  const [modalAction, setModalAction] = useState<'approve' | 'reject' | null>(null);
  const [remarks, setRemarks] = useState('');
  const [modalError, setModalError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const fetchExceptions = async () => {
    setLoading(true);
    try {
      const res = await api.get<IAttendance[]>('/attendance/pending-approvals');
      setExceptions(res.data);
    } catch (err) {
      console.error('Error fetching exceptions:', err);
      setMessage({ text: 'Failed to retrieve attendance exceptions.', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchExceptions();
  }, []);

  // Body scroll lock when modal is open
  useEffect(() => {
    if (selectedException) {
      document.body.classList.add('modal-open');
    } else {
      document.body.classList.remove('modal-open');
    }
    return () => { document.body.classList.remove('modal-open'); };
  }, [selectedException]);



  const openActionModal = (record: IAttendance, action: 'approve' | 'reject') => {
    setSelectedException(record);
    setModalAction(action);
    setRemarks('');
    setModalError(null);
  };

  const closeModal = () => {
    setSelectedException(null);
    setModalAction(null);
    setRemarks('');
    setModalError(null);
  };

  const handleProcessException = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedException || !modalAction) return;

    if (modalAction === 'reject' && !remarks.trim()) {
      setModalError('Remarks are required for rejecting an attendance exception.');
      return;
    }

    setActionLoading(true);
    setModalError(null);
    setMessage(null);

    try {
      const endpoint = `/attendance/${selectedException._id}/${modalAction}`;
      const res = await api.patch(endpoint, { remarks: remarks.trim() });
      
      setMessage({ 
        text: res.data.message || `Exception successfully ${modalAction}d.`, 
        type: 'success' 
      });
      closeModal();
      fetchExceptions();
    } catch (err: any) {
      console.error('Exception process error:', err);
      setModalError(err.response?.data?.message || `Failed to process ${modalAction} request.`);
    } finally {
      setActionLoading(false);
    }
  };

  const formatTime = (timeStr?: string) => {
    if (!timeStr) return '—';
    return new Date(timeStr).toLocaleTimeString(undefined, { 
      hour: '2-digit', 
      minute: '2-digit',
      hour12: true
    });
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString(undefined, { 
      weekday: 'short',
      year: 'numeric', 
      month: 'short', 
      day: 'numeric' 
    });
  };

  return (
    <div className="attendance-exceptions-container fade-in">
      <header className="exceptions-header">
        <div>
          <h1>Attendance Exception Moderation</h1>
          <p className="subtitle">Approve or reject late-arrival and early-checkout exceptions submitted by employees.</p>
        </div>
      </header>

      {message && (
        <div className={`exceptions-alert alert-${message.type === 'success' ? 'success' : 'danger'}`}>
          {message.type === 'success' ? <CheckCircle size={20} /> : <XCircle size={20} />}
          <span>{message.text}</span>
        </div>
      )}

      {/* Exception Records List */}
      <div className="exceptions-list-section glass-card">
        {loading ? (
          <div className="table-loading-exceptions">
            <div className="custom-spinner" />
            <p>SYNCING EXCEPTION LOGS...</p>
          </div>
        ) : exceptions.length > 0 ? (
          <div className="leave-logs-container">
            {/* Desktop Table View */}
            <div className="table-responsive hide-on-mobile">
              <table className="exceptions-table">
                <thead>
                  <tr>
                    <th>Employee</th>
                    <th>Department</th>
                    <th>Date</th>
                    <th>Log Timings</th>
                    <th>Exception Type</th>
                    <th>GPS Coordinates</th>
                    <th className="center-cell">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {exceptions.map((record) => {
                    const emp = record.employeeId as any;
                    return (
                      <tr key={record._id}>
                        <td>
                          {emp ? (
                            <div className="emp-info-cell">
                              <strong>{emp.name}</strong>
                              <span className="emp-email">{emp.email}</span>
                            </div>
                          ) : (
                            <span className="text-muted">Unknown Employee</span>
                          )}
                        </td>
                        <td>
                          <span className="dept-tag">{emp?.department || '—'}</span>
                        </td>
                        <td>
                          <span className="exception-date">
                            <Calendar size={14} className="decor-icon" />
                            {formatDate(record.date)}
                          </span>
                        </td>
                        <td>
                          <div className="timings-cell">
                            <span>Check-in: <strong>{formatTime(record.checkInTime)}</strong></span>
                            {record.checkOutTime && (
                              <span>Check-out: <strong>{formatTime(record.checkOutTime)}</strong></span>
                            )}
                          </div>
                        </td>
                        <td>
                          <div className="exception-types-badges">
                            {record.isLateArrival && (
                              <span className="badge badge-warning">Late Arrival</span>
                            )}
                            {record.isEarlyCheckout && (
                              <span className="badge badge-warning">Early Checkout</span>
                            )}
                            {record.isHolidayWork && (
                              <span className="badge badge-info">Holiday Work</span>
                            )}
                          </div>
                        </td>
                        <td>
                          <div className="gps-details-cell">
                            {record.checkInGps && (
                              <span title="Check-in GPS">
                                <MapPin size={12} />
                                In: {record.checkInGps.latitude.toFixed(4)}, {record.checkInGps.longitude.toFixed(4)}
                              </span>
                            )}
                            {record.checkOutGps && (
                              <span title="Check-out GPS">
                                <MapPin size={12} />
                                Out: {record.checkOutGps.latitude.toFixed(4)}, {record.checkOutGps.longitude.toFixed(4)}
                              </span>
                            )}
                            {!record.checkInGps && !record.checkOutGps && (
                              <span className="text-muted italic">No GPS Logs</span>
                            )}
                          </div>
                        </td>

                        <td className="center-cell actions-cell">
                          <div className="btn-action-group">
                            <button 
                              className="action-btn-circle approve-btn-round"
                              title="Approve Exception"
                              onClick={() => openActionModal(record, 'approve')}
                            >
                              <Check size={16} />
                            </button>
                            <button 
                              className="action-btn-circle reject-btn-round"
                              title="Reject Exception"
                              onClick={() => openActionModal(record, 'reject')}
                            >
                              <X size={16} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* Mobile Card List View */}
            <div className="mobile-cards-list show-on-mobile">
              {exceptions.map((record) => {
                const emp = record.employeeId as any;
                return (
                  <div key={record._id} className="mobile-log-card glass-card">
                    <div className="card-row-header">
                      <div className="emp-avatar-row">
                        <div className="avatar-circle">
                          {emp ? emp.name.charAt(0).toUpperCase() : 'U'}
                        </div>
                        <div className="emp-details">
                          <strong>{emp ? emp.name : 'Unknown Employee'}</strong>
                          <span className="dept-tag margin-top-025rem">{emp?.department || 'No Dept'}</span>
                        </div>
                      </div>
                    </div>
                    
                    <div className="card-row-details">
                      <div className="detail-item">
                        <span className="detail-lbl">Exception Date</span>
                        <span className="detail-val">
                          <Calendar size={12} className="inline-icon" />
                          <strong> {formatDate(record.date)}</strong>
                        </span>
                      </div>

                      <div className="detail-item">
                        <span className="detail-lbl">Log Timings</span>
                        <span className="detail-val">
                          In: <strong>{formatTime(record.checkInTime)}</strong>
                          {record.checkOutTime && (
                            <> | Out: <strong>{formatTime(record.checkOutTime)}</strong></>
                          )}
                        </span>
                      </div>
                      
                      <div className="detail-item">
                        <span className="detail-lbl">Exception Type</span>
                        <div className="exception-types-badges margin-top-025rem">
                          {record.isLateArrival && (
                            <span className="badge badge-warning">Late Arrival</span>
                          )}
                          {record.isEarlyCheckout && (
                            <span className="badge badge-warning">Early Checkout</span>
                          )}
                          {record.isHolidayWork && (
                            <span className="badge badge-info">Holiday Work</span>
                          )}
                        </div>
                      </div>
                      
                      {(record.checkInGps || record.checkOutGps) && (
                        <div className="detail-item">
                          <span className="detail-lbl">GPS Details</span>
                          <div className="gps-details-cell margin-top-025rem">
                            {record.checkInGps && (
                              <span className="gps-log-text">
                                In: {record.checkInGps.latitude.toFixed(4)}, {record.checkInGps.longitude.toFixed(4)}
                              </span>
                            )}
                            {record.checkOutGps && (
                              <span className="gps-log-text">
                                Out: {record.checkOutGps.latitude.toFixed(4)}, {record.checkOutGps.longitude.toFixed(4)}
                              </span>
                            )}
                          </div>
                        </div>
                      )}
                    </div>
                    
                    <div className="card-row-actions gap-05rem">
                      <button 
                        className="btn btn-success flex-1"
                        onClick={() => openActionModal(record, 'approve')}
                      >
                        <Check size={14} />
                        <span>Approve</span>
                      </button>
                      <button 
                        className="btn btn-danger flex-1"
                        onClick={() => openActionModal(record, 'reject')}
                      >
                        <X size={14} />
                        <span>Reject</span>
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        ) : (
          <div className="no-exceptions-view">
            <CheckCircle size={40} className="all-clear-icon" />
            <h3>All Exceptions Handled</h3>
            <p className="text-muted">There are no pending late-arrival or early-checkout exception validations left to moderate.</p>
          </div>
        )}
      </div>

      {/* Exception Remarks Modal */}
      {selectedException && modalAction && (
        <div className="modal-backdrop">
          <div className="modal-box glass-card fade-in">
            <div className="modal-header">
              <h3>{modalAction === 'approve' ? 'Approve Exception' : 'Reject Exception'}</h3>
              <button className="modal-close-btn" onClick={closeModal}>&times;</button>
            </div>
            
            <form onSubmit={handleProcessException}>
              <div className="modal-body">
                <div className="exception-summary-preview">
                  <p>Employee: <strong>{(selectedException.employeeId as any)?.name}</strong></p>
                  <p>Date: <strong>{formatDate(selectedException.date)}</strong></p>
                  <p>Timings: Check-in <strong>{formatTime(selectedException.checkInTime)}</strong> {selectedException.checkOutTime ? `| Check-out ${formatTime(selectedException.checkOutTime)}` : ''}</p>
                  <p>Violations: {selectedException.isLateArrival && <span className="badge badge-warning margin-right-xs">LATE ARRIVAL</span>}{selectedException.isEarlyCheckout && <span className="badge badge-warning">EARLY CHECKOUT</span>}</p>
                </div>

                {modalError && (
                  <div className="modal-error-alert">
                    <AlertTriangle size={16} />
                    <span>{modalError}</span>
                  </div>
                )}

                <div className="form-group">
                  <label className="form-label">
                    Remarks {modalAction === 'reject' && <span className="required-star">*</span>}
                  </label>
                  <textarea 
                    className="form-textarea modal-textarea" 
                    placeholder={modalAction === 'approve' ? 'Optional approval comments...' : 'Provide reasoning for rejecting exception...'}
                    value={remarks}
                    onChange={(e) => setRemarks(e.target.value)}
                    required={modalAction === 'reject'}
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={closeModal} disabled={actionLoading}>
                  Cancel
                </button>
                <button 
                  type="submit" 
                  className={`btn ${modalAction === 'approve' ? 'btn-primary' : 'btn-danger'}`}
                  disabled={actionLoading}
                >
                  {actionLoading ? 'Saving...' : modalAction === 'approve' ? 'Approve Exception' : 'Reject Exception'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default AttendanceExceptions;
