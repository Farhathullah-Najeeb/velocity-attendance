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
  X
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
  const [modalAction, setModalAction] = useState<'approve' | 'reject' | null>(null);
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
  const openActionModal = (leave: ILeave, action: 'approve' | 'reject') => {
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

  // Submit approval/rejection handler
  const handleProcessLeave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedLeave || !modalAction) return;

    if (modalAction === 'reject' && !remarks.trim()) {
      setModalError('Remarks are required for rejecting a leave request.');
      return;
    }

    setActionLoading(true);
    setModalError(null);
    setMessage(null);

    try {
      const endpoint = `/leaves/${selectedLeave._id}/${modalAction}`;
      const res = await api.patch(endpoint, { remarks: remarks.trim() });
      
      setMessage({ 
        text: res.data.message || `Leave request successfully ${modalAction}d.`, 
        type: 'success' 
      });
      closeModal();
      fetchLeaves();
    } catch (err: any) {
      console.error('Leave process error:', err);
      setModalError(err.response?.data?.message || `Failed to process ${modalAction} request.`);
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
    const start = new Date(from);
    const end = new Date(to);
    const diffTime = Math.abs(end.getTime() - start.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
  };

  // Filter leaves locally by employee name search
  const filteredLeaves = leaves.filter(leave => {
    const emp = leave.employeeId as any;
    if (!emp) return false;
    const nameMatch = emp.name?.toLowerCase().includes(searchQuery.toLowerCase());
    const emailMatch = emp.email?.toLowerCase().includes(searchQuery.toLowerCase());
    return nameMatch || emailMatch;
  });

  return (
    <div className="admin-leaves-container fade-in">
      <header className="leaves-header-admin">
        <div>
          <h1>Leave Request Moderation</h1>
          <p className="subtitle">Monitor employee leave requests and process approvals or rejections.</p>
        </div>
      </header>

      {message && (
        <div className={`leaves-alert alert-${message.type === 'success' ? 'success' : 'danger'}`}>
          {message.type === 'success' ? <CheckCircle size={20} /> : <XCircle size={20} />}
          <span>{message.text}</span>
        </div>
      )}

      {/* Filter and Search Bar */}
      <div className="filter-controls-bar glass-card">
        <div className="search-group">
          <Search className="search-icon" size={16} />
          <input 
            type="text" 
            placeholder="Search by employee name..." 
            className="search-input"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="filters-row">
          <div className="filter-item">
            <Filter size={14} className="filter-decor" />
            <select 
              className="filter-select"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="PENDING">Pending Review</option>
              <option value="APPROVED">Approved</option>
              <option value="REJECTED">Rejected</option>
              <option value="">All Statuses</option>
            </select>
          </div>

          <div className="filter-item">
            <Filter size={14} className="filter-decor" />
            <select 
              className="filter-select"
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
            >
              <option value="">All Leave Types</option>
              <option value="CASUAL">Casual Leave</option>
              <option value="SICK">Sick Leave</option>
              <option value="COMPENSATORY">Compensatory Off</option>
              <option value="OTHER">Other Special</option>
            </select>
          </div>
        </div>
      </div>

      {/* Leaves Logs Table */}
      <div className="leaves-list-section glass-card">
        {loading ? (
          <div className="table-loading-admin">
            <div className="custom-spinner" />
            <p>SYNCING LEAVE BALANCE FILES...</p>
          </div>
        ) : filteredLeaves.length > 0 ? (
          <div className="leave-logs-container">
            {/* Desktop Table View */}
            <div className="table-responsive hide-on-mobile">
              <table className="admin-leave-table">
                <thead>
                  <tr>
                    <th>Employee</th>
                    <th>Department</th>
                    <th>Leave Type</th>
                    <th>Duration</th>
                    <th className="center-cell">Days</th>
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
                            <span className="text-muted">Unknown Employee</span>
                          )}
                        </td>
                        <td>
                          <span className="dept-tag">{emp?.department || '—'}</span>
                        </td>
                        <td>
                          <span className={`leave-type-indicator type-${leave.type.toLowerCase()}`}>
                            {leave.type}
                          </span>
                        </td>
                        <td>
                          <span className="date-range">
                            {formatDate(leave.fromDate)} to {formatDate(leave.toDate)}
                          </span>
                        </td>
                        <td className="center-cell">{days}</td>
                        <td className="reason-cell" title={leave.reason}>{leave.reason}</td>
                        <td>
                          <span className={`badge badge-${
                            leave.status === 'APPROVED' ? 'success' : 
                            leave.status === 'REJECTED' ? 'danger' : 'warning'
                          }`}>
                            {leave.status}
                          </span>
                        </td>
                        <td className="center-cell actions-cell">
                          {leave.status === 'PENDING' ? (
                            <div className="btn-action-group">
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
                    
                    {leave.status === 'PENDING' && (
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
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        ) : (
          <p className="text-muted padding-2rem text-center">No leave applications match the selected criteria.</p>
        )}
      </div>

      {/* Approve/Reject Modal Popup */}
      {selectedLeave && modalAction && (
        <div className="modal-backdrop">
          <div className="modal-box glass-card fade-in">
            <div className="modal-header">
              <h3>{modalAction === 'approve' ? 'Approve Leave Request' : 'Reject Leave Request'}</h3>
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
                    Remarks {modalAction === 'reject' && <span className="required-star">*</span>}
                  </label>
                  <textarea 
                    className="form-textarea modal-textarea" 
                    placeholder={modalAction === 'approve' ? 'Enter optional approval comments...' : 'Please specify the reason for rejection...'}
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
                  {actionLoading ? 'Saving...' : modalAction === 'approve' ? 'Approve Request' : 'Reject Request'}
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
