import React, { useState, useEffect } from 'react';
import api from '../services/api';
import type { ILeave } from '../types';
import { 
  CheckCircle, 
  XCircle, 
  Clock, 
  Filter, 
  MessageSquare,
  Search,
  Check,
  X,
  RotateCcw
} from 'lucide-react';
import './AdminLeaveManagement.css';

const AdminLeaveManagement: React.FC = () => {
  const [leaves, setLeaves] = useState<ILeave[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Filters
  const [statusFilter, setStatusFilter] = useState<string>('PENDING');
  const [typeFilter, setTypeFilter] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Remarks modal states
  const [selectedLeave, setSelectedLeave] = useState<ILeave | null>(null);
  const [modalAction, setModalAction] = useState<'approve' | 'reject' | 'revoke' | null>(null);
  const [remarks, setRemarks] = useState('');
  const [modalError, setModalError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const fetchLeaves = async () => {
    setLoading(true);
    try {
      const params: Record<string, string> = {};
      if (statusFilter) params.status = statusFilter;
      if (typeFilter) params.type = typeFilter;

      const res = await api.get<ILeave[]>('/leaves', { params });
      setLeaves(res.data);
    } catch (err) {
      console.error('Error fetching leaves:', err);
      setMessage({ text: 'Failed to retrieve leave logs.', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLeaves();
  }, [statusFilter, typeFilter]);

  // Body scroll lock when action modal is open
  useEffect(() => {
    if (selectedLeave) {
      document.body.classList.add('modal-open');
    } else {
      document.body.classList.remove('modal-open');
    }
    return () => { document.body.classList.remove('modal-open'); };
  }, [selectedLeave]);

  // Open modal handler
  const openActionModal = (leave: ILeave, action: 'approve' | 'reject' | 'revoke') => {
    setSelectedLeave(leave);
    setModalAction(action);
    setRemarks('');
    setModalError(null);
  };

  // Close modal
  const closeModal = () => {
    setSelectedLeave(null);
    setModalAction(null);
    setRemarks('');
    setModalError(null);
  };

  // Submit approval/rejection/revoke handler
  const handleProcessLeave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedLeave || !modalAction) return;

    if ((modalAction === 'reject' || modalAction === 'revoke') && !remarks.trim()) {
      setModalError(`Remarks are required for ${modalAction}ing a leave request.`);
      return;
    }

    setActionLoading(true);
    setModalError(null);
    setMessage(null);

    try {
      const endpoint = `/leaves/${selectedLeave._id}/${modalAction}`;
      const res = await api.patch(endpoint, { remarks: remarks.trim() });
      
      setMessage({ 
        text: res.data.message || `Leave request ${modalAction}d successfully.`, 
        type: 'success' 
      });
      closeModal();
      fetchLeaves();
    } catch (err: any) {
      console.error('Leave process error:', err);
      setModalError(err.response?.data?.message || `Failed to ${modalAction} leave request.`);
    } finally {
      setActionLoading(false);
    }
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString(undefined, { 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric' 
    });
  };

  const calculateDays = (from: string, to: string) => {
    const d1 = new Date(from);
    const d2 = new Date(to);
    const diffTime = Math.abs(d2.getTime() - d1.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
  };

  const filteredLeaves = leaves.filter(l => {
    const empName = (l.employeeId as any)?.name || '';
    const empEmail = (l.employeeId as any)?.email || '';
    const q = searchQuery.toLowerCase();
    return empName.toLowerCase().includes(q) || empEmail.toLowerCase().includes(q) || l.reason.toLowerCase().includes(q);
  });

  return (
    <div className="admin-leave-management-container fade-in">
      <header className="leave-header">
        <div>
          <h1>Leave Management Hub</h1>
          <p className="subtitle">Review, approve, reject, or revoke employee leave applications across departments.</p>
        </div>
      </header>

      {message && (
        <div className={`leave-alert alert-${message.type === 'success' ? 'success' : 'danger'}`}>
          {message.type === 'success' ? <CheckCircle size={20} /> : <XCircle size={20} />}
          <span>{message.text}</span>
        </div>
      )}

      {/* Control Panel: Filters & Search */}
      <div className="control-panel glass-card">
        <div className="search-box flex-1">
          <Search size={18} className="search-icon" />
          <input 
            type="text" 
            placeholder="Search by employee name, email, or reason..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="search-input"
          />
        </div>

        <div className="filters-group">
          <div className="filter-item">
            <Filter size={16} className="filter-icon" />
            <select 
              value={statusFilter} 
              onChange={(e) => setStatusFilter(e.target.value)}
              className="filter-select"
            >
              <option value="">All Statuses</option>
              <option value="PENDING">Pending Only</option>
              <option value="APPROVED">Approved Only</option>
              <option value="REJECTED">Rejected Only</option>
            </select>
          </div>

          <div className="filter-item">
            <select 
              value={typeFilter} 
              onChange={(e) => setTypeFilter(e.target.value)}
              className="filter-select"
            >
              <option value="">All Leave Types</option>
              <option value="CASUAL">Casual Leave</option>
              <option value="SICK">Sick Leave</option>
              <option value="COMPENSATORY">Compensatory Off</option>
              <option value="OTHER">Other</option>
            </select>
          </div>
        </div>
      </div>

      {/* Leaves Applications Table / List */}
      <div className="leave-logs-section glass-card">
        {loading ? (
          <div className="table-loading-leaves">
            <div className="custom-spinner" />
            <p>SYNCING LEAVE APPLICATIONS...</p>
          </div>
        ) : filteredLeaves.length > 0 ? (
          <div className="leave-logs-container">
            {/* Desktop Table View */}
            <div className="table-responsive hide-on-mobile">
              <table className="leaves-table">
                <thead>
                  <tr>
                    <th>Employee</th>
                    <th>Department</th>
                    <th>Leave Type</th>
                    <th>Duration</th>
                    <th>Reason</th>
                    <th>Status</th>
                    <th className="center-cell">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredLeaves.map((leave) => {
                    const emp = leave.employeeId as any;
                    const days = calculateDays(leave.fromDate, leave.toDate);
                    return (
                      <tr key={leave._id}>
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
                          <span className={`leave-type-indicator type-${leave.type.toLowerCase()}`}>
                            {leave.type}
                          </span>
                        </td>
                        <td>
                          <div className="duration-cell">
                            <strong>{formatDate(leave.fromDate)}</strong>
                            <span className="to-arrow">→</span>
                            <strong>{formatDate(leave.toDate)}</strong>
                            <span className="days-cnt">({days} {days === 1 ? 'day' : 'days'})</span>
                          </div>
                        </td>
                        <td>
                          <span className="reason-text" title={leave.reason}>{leave.reason}</span>
                        </td>
                        <td>
                          <span className={`badge badge-${
                            leave.status === 'APPROVED' ? 'success' : 
                            leave.status === 'REJECTED' ? 'danger' : 'warning'
                          }`}>
                            {leave.status}
                          </span>
                        </td>
                        <td>
                          {leave.status === 'PENDING' ? (
                            <div className="action-buttons-cell">
                              <button 
                                className="btn-action approve"
                                onClick={() => openActionModal(leave, 'approve')}
                              >
                                Approve
                              </button>
                              <button 
                                className="btn-action reject"
                                onClick={() => openActionModal(leave, 'reject')}
                              >
                                Reject
                              </button>
                            </div>
                          ) : leave.status === 'APPROVED' ? (
                            <div className="action-buttons-cell">
                              <button 
                                className="btn-action reject"
                                title="Revoke Approved Leave"
                                onClick={() => openActionModal(leave, 'revoke')}
                              >
                                <RotateCcw size={12} className="inline-icon" /> Revoke
                              </button>
                            </div>
                          ) : (
                            <div className="processed-remarks-cell">
                              {leave.remarks ? (
                                <span className="remark-text" title={leave.remarks}>
                                  <MessageSquare size={14} />
                                  "{leave.remarks}"
                                </span>
                              ) : (
                                <span className="text-muted italic">No remarks</span>
                              )}
                            </div>
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
              {filteredLeaves.map((leave) => {
                const emp = leave.employeeId as any;
                const days = calculateDays(leave.fromDate, leave.toDate);
                return (
                  <div key={leave._id} className="mobile-log-card glass-card">
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
                      <span className={`badge badge-${
                        leave.status === 'APPROVED' ? 'success' : 
                        leave.status === 'REJECTED' ? 'danger' : 'warning'
                      }`}>
                        {leave.status}
                      </span>
                    </div>
                    
                    <div className="card-row-details">
                      <div className="detail-item">
                        <span className="detail-lbl">Leave Type</span>
                        <span className="detail-val">
                          <span className={`leave-type-indicator type-${leave.type.toLowerCase()}`}>
                            {leave.type}
                          </span>
                        </span>
                      </div>

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
                          <span className="detail-lbl">Admin Remarks</span>
                          <span className="detail-val italic">"{leave.remarks}"</span>
                        </div>
                      )}
                    </div>
                    
                    {leave.status === 'PENDING' ? (
                      <div className="card-row-actions gap-05rem">
                        <button 
                          className="btn btn-success flex-1"
                          onClick={() => openActionModal(leave, 'approve')}
                        >
                          <Check size={14} />
                          <span>Approve</span>
                        </button>
                        <button 
                          className="btn btn-danger flex-1"
                          onClick={() => openActionModal(leave, 'reject')}
                        >
                          <X size={14} />
                          <span>Reject</span>
                        </button>
                      </div>
                    ) : leave.status === 'APPROVED' ? (
                      <div className="card-row-actions gap-05rem">
                        <button 
                          className="btn btn-danger flex-1"
                          onClick={() => openActionModal(leave, 'revoke')}
                        >
                          <RotateCcw size={14} />
                          <span>Revoke Leave</span>
                        </button>
                      </div>
                    ) : null}
                  </div>
                );
              })}
            </div>
          </div>
        ) : (
          <p className="text-muted padding-2rem text-center">No leave applications match the selected criteria.</p>
        )}
      </div>

      {/* Approve/Reject/Revoke Modal Popup */}
      {selectedLeave && modalAction && (
        <div className="modal-backdrop">
          <div className="modal-box glass-card fade-in">
            <div className="modal-header">
              <h3>{modalAction === 'approve' ? 'Approve Leave Request' : modalAction === 'reject' ? 'Reject Leave Request' : 'Revoke Approved Leave'}</h3>
              <button className="modal-close-btn" onClick={closeModal}>&times;</button>
            </div>
            
            <form onSubmit={handleProcessLeave}>
              <div className="modal-body">
                <div className="leave-summary-preview">
                  <p>Employee: <strong>{(selectedLeave.employeeId as any)?.name}</strong></p>
                  <p>Duration: <strong>{formatDate(selectedLeave.fromDate)}</strong> to <strong>{formatDate(selectedLeave.toDate)}</strong> ({calculateDays(selectedLeave.fromDate, selectedLeave.toDate)} days)</p>
                  <p>Type: <span className={`leave-type-indicator type-${selectedLeave.type.toLowerCase()}`}>{selectedLeave.type}</span></p>
                </div>

                {modalError && (
                  <div className="modal-error-alert">
                    <Clock size={16} />
                    <span>{modalError}</span>
                  </div>
                )}

                <div className="form-group">
                  <label className="form-label">
                    Remarks {(modalAction === 'reject' || modalAction === 'revoke') && <span className="required-star">*</span>}
                  </label>
                  <textarea 
                    className="form-textarea modal-textarea" 
                    placeholder={modalAction === 'approve' ? 'Enter optional approval comments...' : modalAction === 'revoke' ? 'Specify reasoning for revoking this approved leave...' : 'Please specify the reason for rejection...'}
                    value={remarks}
                    onChange={(e) => setRemarks(e.target.value)}
                    required={modalAction === 'reject' || modalAction === 'revoke'}
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
                  {actionLoading ? 'Saving...' : modalAction === 'approve' ? 'Approve Request' : modalAction === 'revoke' ? 'Revoke Leave' : 'Reject Request'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default AdminLeaveManagement;
