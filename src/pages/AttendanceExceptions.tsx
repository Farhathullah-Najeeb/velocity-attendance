import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { useToast } from '../context/ToastContext';
import SkeletonLoader from '../components/SkeletonLoader';
import EmptyState from '../components/EmptyState';
import type { IAttendance, IOvertime } from '../types';
import { 
  MapPin, 
  Calendar,
  Check,
  X,
  AlertTriangle,
  CheckCircle,
  ShieldAlert,
  Clock
} from 'lucide-react';
import './AttendanceExceptions.css';

const AttendanceExceptions: React.FC = () => {
  // Tab state: 'attendance' | 'overtime'
  const [activeTab, setActiveTab] = useState<'attendance' | 'overtime'>('attendance');

  // Attendance Exception States
  const [exceptions, setExceptions] = useState<IAttendance[]>([]);
  const [loadingExceptions, setLoadingExceptions] = useState(true);
  
  // Overtime Pending States
  const [overtimes, setOvertimes] = useState<IOvertime[]>([]);
  const [loadingOvertimes, setLoadingOvertimes] = useState(false);

  // Attendance Modal states
  const [selectedException, setSelectedException] = useState<IAttendance | null>(null);
  const [modalAction, setModalAction] = useState<'approve' | 'reject' | 'penalty' | null>(null);
  const [penaltyType, setPenaltyType] = useState<'RED_MARK' | 'HALF_DAY' | 'NONE'>('HALF_DAY');
  const [remarks, setRemarks] = useState('');
  const [modalError, setModalError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  // Overtime Action Modal states
  const [selectedOt, setSelectedOt] = useState<IOvertime | null>(null);
  const [otAction, setOtAction] = useState<'approve' | 'reject' | null>(null);
  const [otRemarks, setOtRemarks] = useState('');

  // General Notification Alert
  const { showToast } = useToast();
  const setMessage = (msg: { text: string; type: 'success' | 'error' | 'info' } | null) => {
    if (msg) showToast(msg.text, msg.type);
  };

  const fetchExceptions = async () => {
    setLoadingExceptions(true);
    try {
      const res = await api.get<IAttendance[]>('/attendance/pending-approvals');
      setExceptions(res.data);
    } catch (err) {
      console.error('Error fetching exceptions:', err);
      setMessage({ text: 'Failed to retrieve attendance exceptions.', type: 'error' });
    } finally {
      setLoadingExceptions(false);
    }
  };

  const fetchOvertimes = async () => {
    setLoadingOvertimes(true);
    try {
      const res = await api.get<IOvertime[]>('/overtime/pending');
      setOvertimes(res.data);
    } catch (err) {
      console.error('Error fetching pending overtime:', err);
    } finally {
      setLoadingOvertimes(false);
    }
  };

  useEffect(() => {
    fetchExceptions();
    fetchOvertimes();
  }, []);

  // Body scroll lock when modal is open
  useEffect(() => {
    if (selectedException || selectedOt) {
      document.body.classList.add('modal-open');
    } else {
      document.body.classList.remove('modal-open');
    }
    return () => { document.body.classList.remove('modal-open'); };
  }, [selectedException, selectedOt]);

  const openActionModal = (record: IAttendance, action: 'approve' | 'reject' | 'penalty') => {
    setSelectedException(record);
    setModalAction(action);
    setRemarks('');
    setPenaltyType('HALF_DAY');
    setModalError(null);
  };

  const closeModal = () => {
    setSelectedException(null);
    setModalAction(null);
    setRemarks('');
    setModalError(null);
  };

  const openOtModal = (ot: IOvertime, action: 'approve' | 'reject') => {
    setSelectedOt(ot);
    setOtAction(action);
    setOtRemarks('');
    setModalError(null);
  };

  const closeOtModal = () => {
    setSelectedOt(null);
    setOtAction(null);
    setOtRemarks('');
    setModalError(null);
  };

  // Process Attendance Exception Action
  const handleProcessException = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedException || !modalAction) return;

    if (modalAction === 'reject' && !remarks.trim()) {
      setModalError('Remarks are required for rejecting an attendance exception.');
      return;
    }

    if (modalAction === 'penalty' && !remarks.trim()) {
      setModalError('Remarks are required for applying a penalty.');
      return;
    }

    setActionLoading(true);
    setModalError(null);

    try {
      const endpoint = `/attendance/${selectedException._id}/${modalAction}`;
      const payload: any = { remarks: remarks.trim() };
      if (modalAction === 'penalty') {
        payload.penaltyType = penaltyType;
      }
      
      const res = await api.patch(endpoint, payload);
      
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

  // Process Overtime Action
  const handleProcessOvertime = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedOt || !otAction) return;

    if (otAction === 'reject' && !otRemarks.trim()) {
      setModalError('Remarks are required when rejecting overtime work.');
      return;
    }

    setActionLoading(true);
    setModalError(null);

    try {
      const endpoint = `/overtime/${selectedOt._id}/${otAction}`;
      const res = await api.patch(endpoint, { remarks: otRemarks.trim() });
      setMessage({
        text: res.data.message || `Overtime request ${otAction}d successfully.`,
        type: 'success'
      });
      closeOtModal();
      fetchOvertimes();
    } catch (err: any) {
      console.error('Overtime process error:', err);
      setModalError(err.response?.data?.message || `Failed to process overtime ${otAction}.`);
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
          <h1>Moderation Center</h1>
          <p className="subtitle">Moderate pending attendance exceptions and overtime requests submitted by employees.</p>
        </div>
        {/* Tabs */}
        <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem', borderBottom: '1px solid var(--border-color)', paddingBottom: '0.75rem' }}>
          <button
            className={`btn ${activeTab === 'attendance' ? 'btn-primary' : 'btn-secondary'}`}
            onClick={() => setActiveTab('attendance')}
          >
            <AlertTriangle size={16} />
            <span>Attendance Exceptions ({exceptions.length})</span>
          </button>

          <button
            className={`btn ${activeTab === 'overtime' ? 'btn-primary' : 'btn-secondary'}`}
            onClick={() => setActiveTab('overtime')}
          >
            <Clock size={16} />
            <span>Overtime Requests ({overtimes.length})</span>
          </button>
        </div>
      </header>

      {/* EXCEPTIONS TAB */}
      {activeTab === 'attendance' && (
        <div className="exceptions-list-section glass-card">
          {loadingExceptions ? (
            <SkeletonLoader type="table" count={5} />
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
                      <th>GPS Details</th>
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
                              'Unknown'
                            )}
                          </td>
                          <td>
                            <span className="badge badge-neutral">{emp?.department || 'N/A'}</span>
                          </td>
                          <td>
                            <strong>{formatDate(record.date)}</strong>
                          </td>
                          <td>
                            <div className="timings-cell">
                              <span>In: <strong>{formatTime(record.checkInTime)}</strong></span>
                              {record.checkOutTime && (
                                <span>Out: <strong>{formatTime(record.checkOutTime)}</strong></span>
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
                            {record.checkInGps || record.checkOutGps ? (
                              <div className="gps-details-cell">
                                {record.checkInGps && (
                                  <span className="gps-log-text">
                                    <MapPin size={10} className="inline-icon" /> In: {record.checkInGps.latitude.toFixed(4)}, {record.checkInGps.longitude.toFixed(4)}
                                  </span>
                                )}
                                {record.checkOutGps && (
                                  <span className="gps-log-text">
                                    <MapPin size={10} className="inline-icon" /> Out: {record.checkOutGps.latitude.toFixed(4)}, {record.checkOutGps.longitude.toFixed(4)}
                                  </span>
                                )}
                              </div>
                            ) : (
                              <span className="text-muted">No GPS</span>
                            )}
                          </td>
                          <td>
                            <div className="action-buttons-cell">
                              <button 
                                className="btn-icon btn-icon-success"
                                title="Approve Exception"
                                onClick={() => openActionModal(record, 'approve')}
                              >
                                <Check size={16} />
                              </button>
                              <button 
                                className="btn-icon btn-icon-danger"
                                title="Reject Exception"
                                onClick={() => openActionModal(record, 'reject')}
                              >
                                <X size={16} />
                              </button>
                              <button 
                                className="btn-icon btn-icon-warning"
                                title="Apply Penalty"
                                onClick={() => openActionModal(record, 'penalty')}
                              >
                                <ShieldAlert size={16} />
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
                    <div key={record._id} className="mobile-exception-card">
                      <div className="card-header-row">
                        <div>
                          <h4 className="emp-name-title">{emp?.name || 'Unknown Employee'}</h4>
                          <span className="badge badge-neutral margin-top-025rem">{emp?.department || 'N/A'}</span>
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
                        <button 
                          className="btn btn-secondary flex-1"
                          onClick={() => openActionModal(record, 'penalty')}
                        >
                          <ShieldAlert size={14} />
                          <span>Penalty</span>
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ) : (
            <EmptyState 
              icon={<CheckCircle size={48} strokeWidth={1.5} style={{ color: 'var(--color-success)' }} />}
              title="All Attendance Exceptions Handled" 
              description="There are no pending late-arrival or early-checkout exception validations left to moderate." 
            />
          )}
        </div>
      )}

      {/* OVERTIME REQUESTS TAB */}
      {activeTab === 'overtime' && (
        <div className="exceptions-list-section glass-card">
          {loadingOvertimes ? (
            <SkeletonLoader type="table" count={5} />
          ) : overtimes.length > 0 ? (
            <div className="leave-logs-container">
              <div className="table-responsive hide-on-mobile">
                <table className="exceptions-table">
                  <thead>
                    <tr>
                      <th>Employee</th>
                      <th>Date</th>
                      <th>Start Time</th>
                      <th>End Time</th>
                      <th>Duration</th>
                      <th>Summary</th>
                      <th className="center-cell">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {overtimes.map((ot) => {
                      const emp = ot.employeeId as any;
                      return (
                        <tr key={ot._id}>
                          <td>
                            <strong>{emp?.name || 'Employee'}</strong>
                            <div className="text-muted" style={{ fontSize: '0.8rem' }}>{emp?.department}</div>
                          </td>
                          <td><strong>{ot.dateStr}</strong></td>
                          <td>{formatTime(ot.startTime)}</td>
                          <td>{formatTime(ot.endTime)}</td>
                          <td><span className="badge badge-info">{(ot.overtimeMinutes / 60).toFixed(1)} hrs ({ot.overtimeMinutes} mins)</span></td>
                          <td><span className="text-muted">{ot.workSummary}</span></td>
                          <td>
                            <div className="action-buttons-cell">
                              <button 
                                className="btn-icon btn-icon-success"
                                title="Approve Overtime"
                                onClick={() => openOtModal(ot, 'approve')}
                              >
                                <Check size={16} />
                              </button>
                              <button 
                                className="btn-icon btn-icon-danger"
                                title="Reject Overtime"
                                onClick={() => openOtModal(ot, 'reject')}
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

              {/* Mobile Cards for Overtime */}
              <div className="mobile-cards-list show-on-mobile">
                {overtimes.map((ot) => {
                  const emp = ot.employeeId as any;
                  return (
                    <div key={ot._id} className="mobile-exception-card">
                      <h4>{emp?.name || 'Employee'}</h4>
                      <p>Date: <strong>{ot.dateStr}</strong></p>
                      <p>Time: <strong>{formatTime(ot.startTime)} - {formatTime(ot.endTime)}</strong> ({ot.overtimeMinutes} mins)</p>
                      <p>Summary: {ot.workSummary}</p>
                      <div className="card-row-actions gap-05rem margin-top-05rem">
                        <button className="btn btn-success flex-1" onClick={() => openOtModal(ot, 'approve')}>
                          <Check size={14} /> Approve
                        </button>
                        <button className="btn btn-danger flex-1" onClick={() => openOtModal(ot, 'reject')}>
                          <X size={14} /> Reject
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ) : (
            <EmptyState 
              icon={<CheckCircle size={48} strokeWidth={1.5} style={{ color: 'var(--color-success)' }} />}
              title="No Pending Overtime Requests" 
              description="All overtime requests have been moderated." 
            />
          )}
        </div>
      )}

      {/* Attendance Modal */}
      {selectedException && modalAction && (
        <div className="modal-backdrop">
          <div className="modal-box glass-card fade-in">
            <div className="modal-header">
              <h3>{modalAction === 'approve' ? 'Approve Exception' : modalAction === 'reject' ? 'Reject Exception' : 'Apply Manual Penalty'}</h3>
              <button className="modal-close-btn" onClick={closeModal}>&times;</button>
            </div>
            
            <form onSubmit={handleProcessException}>
              <div className="modal-body">
                <div className="exception-summary-preview">
                  <p>Employee: <strong>{(selectedException.employeeId as any)?.name}</strong></p>
                  <p>Date: <strong>{formatDate(selectedException.date)}</strong></p>
                  <p>Timings: Check-in <strong>{formatTime(selectedException.checkInTime)}</strong> {selectedException.checkOutTime ? `| Check-out ${formatTime(selectedException.checkOutTime)}` : ''}</p>
                </div>

                {modalError && (
                  <div className="modal-error-alert">
                    <AlertTriangle size={16} />
                    <span>{modalError}</span>
                  </div>
                )}
                
                {modalAction === 'penalty' && (
                  <div className="form-group">
                    <label className="form-label">
                      Penalty Type <span className="required-star">*</span>
                    </label>
                    <select
                      className="form-input modal-input"
                      value={penaltyType}
                      onChange={(e) => setPenaltyType(e.target.value as any)}
                      required
                    >
                      <option value="HALF_DAY">HALF_DAY Penalty</option>
                      <option value="RED_MARK">RED_MARK Warning</option>
                      <option value="NONE">NONE (Waive Penalty)</option>
                    </select>
                  </div>
                )}

                <div className="form-group">
                  <label className="form-label">
                    Remarks {(modalAction === 'reject' || modalAction === 'penalty') && <span className="required-star">*</span>}
                  </label>
                  <textarea 
                    className="form-textarea modal-textarea" 
                    placeholder={modalAction === 'approve' ? 'Optional approval comments...' : 'Provide reasoning...'}
                    value={remarks}
                    onChange={(e) => setRemarks(e.target.value)}
                    required={modalAction === 'reject' || modalAction === 'penalty'}
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
                  {actionLoading ? 'Saving...' : modalAction === 'approve' ? 'Approve Exception' : modalAction === 'reject' ? 'Reject Exception' : 'Apply Penalty'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Overtime Modal */}
      {selectedOt && otAction && (
        <div className="modal-backdrop">
          <div className="modal-box glass-card fade-in">
            <div className="modal-header">
              <h3>{otAction === 'approve' ? 'Approve Overtime' : 'Reject Overtime'}</h3>
              <button className="modal-close-btn" onClick={closeOtModal}>&times;</button>
            </div>
            
            <form onSubmit={handleProcessOvertime}>
              <div className="modal-body">
                <p>Employee: <strong>{(selectedOt.employeeId as any)?.name}</strong></p>
                <p>Overtime: <strong>{selectedOt?.dateStr || ''} ({selectedOt.overtimeMinutes} mins)</strong></p>
                <p>Work Summary: {selectedOt.workSummary}</p>

                {modalError && (
                  <div className="modal-error-alert margin-top-05rem">
                    <AlertTriangle size={16} />
                    <span>{modalError}</span>
                  </div>
                )}

                <div className="form-group margin-top-1rem">
                  <label className="form-label">
                    Remarks {otAction === 'reject' && <span className="required-star">*</span>}
                  </label>
                  <textarea 
                    className="form-textarea modal-textarea"
                    placeholder="Approval comments or rejection reasoning..."
                    value={otRemarks}
                    onChange={(e) => setOtRemarks(e.target.value)}
                    required={otAction === 'reject'}
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={closeOtModal} disabled={actionLoading}>
                  Cancel
                </button>
                <button type="submit" className={`btn ${otAction === 'approve' ? 'btn-primary' : 'btn-danger'}`} disabled={actionLoading}>
                  {actionLoading ? 'Processing...' : otAction === 'approve' ? 'Approve' : 'Reject'}
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
