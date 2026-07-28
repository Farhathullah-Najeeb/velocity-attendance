import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { useAuth } from '../context/AuthContext';
import type { IUser } from '../types';
import { 
  CheckCircle, 
  XCircle, 
  UserPlus, 
  Search, 
  Users, 
  AlertCircle, 
  ShieldCheck, 
  Check, 
  X, 
  Edit2, 
  Power
} from 'lucide-react';
import './EmployeeManagement.css';

const EmployeeManagement: React.FC = () => {
  const { user } = useAuth();
  const isSuperAdmin = user?.role === 'SUPER_ADMIN';

  // Employees lists
  const [employees, setEmployees] = useState<IUser[]>([]);
  const [admins, setAdmins] = useState<IUser[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Tab control: 'approved' | 'pending' | 'admins'
  const [activeTab, setActiveTab] = useState<'approved' | 'pending' | 'admins'>('approved');
  const [searchQuery, setSearchQuery] = useState('');

  // Modals status
  const [showAddEmployeeModal, setShowAddEmployeeModal] = useState(false);
  const [showAddAdminModal, setShowAddAdminModal] = useState(false);
  const [editingEmployee, setEditingEmployee] = useState<IUser | null>(null);

  // Direct Create Employee Form
  const [empName, setEmpName] = useState('');
  const [empEmail, setEmpEmail] = useState('');
  const [empPassword, setEmpPassword] = useState('');
  const [empDept, setEmpDept] = useState('');
  const [empErrors, setEmpErrors] = useState<Record<string, string>>({});

  // Direct Create Admin Form
  const [admName, setAdmName] = useState('');
  const [admEmail, setAdmEmail] = useState('');
  const [admPassword, setAdmPassword] = useState('');
  const [admRole, setAdmRole] = useState<'ADMIN' | 'SUPER_ADMIN'>('ADMIN');
  const [admErrors, setAdmErrors] = useState<Record<string, string>>({});

  // Edit Employee Form
  const [editName, setEditName] = useState('');
  const [editEmail, setEditEmail] = useState('');
  const [editDept, setEditDept] = useState('');
  const [editErrors, setEditErrors] = useState<Record<string, string>>({});

  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [modalSubmitting, setModalSubmitting] = useState(false);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      if (activeTab === 'admins') {
        const res = await api.get<IUser[]>('/admin/list');
        setAdmins(res.data);
      } else {
        const status = activeTab === 'pending' ? 'PENDING' : 'APPROVED';
        const res = await api.get<IUser[]>('/employees', {
          params: { status }
        });
        setEmployees(res.data);
      }
    } catch (err) {
      console.error('Error fetching users:', err);
      setMessage({ text: 'Failed to retrieve user registry.', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [activeTab]);

  // Create Employee submission handler
  const handleCreateEmployeeSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setMessage(null);

    // Client-side validations
    const errors: Record<string, string> = {};
    if (!empName.trim()) {
      errors.name = 'Full Name is required.';
    }
    
    if (!empEmail.trim()) {
      errors.email = 'Email Address is required.';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(empEmail.trim())) {
      errors.email = 'Please enter a valid email address.';
    }
    
    if (!empPassword) {
      errors.password = 'Password is required.';
    } else if (empPassword.length < 6) {
      errors.password = 'Password must be at least 6 characters.';
    }
    
    if (!empDept.trim()) {
      errors.department = 'Department is required.';
    }
    
    if (Object.keys(errors).length > 0) {
      setEmpErrors(errors);
      return;
    }
    setEmpErrors({});

    setModalSubmitting(true);
    try {
      const res = await api.post('/employees/register', {
        name: empName.trim(),
        email: empEmail.trim(),
        password: empPassword,
        department: empDept.trim()
      });
      setMessage({ text: res.data.message || 'Employee created successfully.', type: 'success' });
      setShowAddEmployeeModal(false);
      
      // Clear Form fields
      setEmpName('');
      setEmpEmail('');
      setEmpPassword('');
      setEmpDept('');
      
      if (activeTab === 'approved') fetchUsers();
      else setActiveTab('approved');
    } catch (err: any) {
      console.error('Create employee error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to create employee.', type: 'error' });
    } finally {
      setModalSubmitting(false);
    }
  };

  // Create Admin submission handler
  const handleCreateAdminSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setMessage(null);

    // Client-side validations
    const errors: Record<string, string> = {};
    if (!admName.trim()) {
      errors.name = 'Full Name is required.';
    }
    
    if (!admEmail.trim()) {
      errors.email = 'Email Address is required.';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(admEmail.trim())) {
      errors.email = 'Please enter a valid email address.';
    }
    
    if (!admPassword) {
      errors.password = 'Password is required.';
    } else if (admPassword.length < 6) {
      errors.password = 'Password must be at least 6 characters.';
    }

    if (Object.keys(errors).length > 0) {
      setAdmErrors(errors);
      return;
    }
    setAdmErrors({});

    setModalSubmitting(true);
    try {
      const res = await api.post('/admin/create', {
        name: admName.trim(),
        email: admEmail.trim(),
        password: admPassword,
        role: admRole
      });
      setMessage({ text: res.data.message || 'Admin account created successfully.', type: 'success' });
      setShowAddAdminModal(false);
      
      // Clear Form fields
      setAdmName('');
      setAdmEmail('');
      setAdmPassword('');
      setAdmRole('ADMIN');
      
      fetchUsers();
    } catch (err: any) {
      console.error('Create admin error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to create admin account.', type: 'error' });
    } finally {
      setModalSubmitting(false);
    }
  };

  // Edit Employee modal opener
  const openEditModal = (emp: IUser) => {
    setEditingEmployee(emp);
    setEditName(emp.name);
    setEditEmail(emp.email);
    setEditDept(emp.department || '');
    setEditErrors({});
  };

  // Edit Employee submission handler
  const handleEditEmployeeSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingEmployee) return;
    setMessage(null);

    // Client-side validations
    const errors: Record<string, string> = {};
    if (!editName.trim()) {
      errors.name = 'Full name is required.';
    }
    if (!editEmail.trim()) {
      errors.email = 'Email address is required.';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(editEmail.trim())) {
      errors.email = 'Please provide a valid email address.';
    }
    if (!editDept.trim()) {
      errors.department = 'Department is required.';
    }

    if (Object.keys(errors).length > 0) {
      setEditErrors(errors);
      return;
    }
    setEditErrors({});

    setModalSubmitting(true);
    try {
      const res = await api.patch(`/employees/${editingEmployee._id}`, {
        name: editName.trim(),
        email: editEmail.trim(),
        department: editDept.trim()
      });
      setMessage({ text: res.data.message || 'Employee details updated successfully.', type: 'success' });
      setEditingEmployee(null);
      fetchUsers();
    } catch (err: any) {
      console.error('Edit employee error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to update employee details.', type: 'error' });
    } finally {
      setModalSubmitting(false);
    }
  };

  // Registration approvals handler
  const handleApprove = async (id: string) => {
    setMessage(null);
    setActionLoadingId(id);
    try {
      const res = await api.patch(`/employees/${id}/approve`);
      setMessage({ text: res.data.message || 'Registration request approved.', type: 'success' });
      fetchUsers();
    } catch (err: any) {
      console.error('Approval error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to approve request.', type: 'error' });
    } finally {
      setActionLoadingId(null);
    }
  };

  // Registration rejection handler
  const handleReject = async (id: string) => {
    if (!window.confirm('Are you sure you want to reject this employee registration? This will permanently delete their account.')) {
      return;
    }
    setMessage(null);
    setActionLoadingId(id);
    try {
      const res = await api.delete(`/employees/${id}/reject`);
      setMessage({ text: res.data.message || 'Registration request rejected and removed.', type: 'success' });
      fetchUsers();
    } catch (err: any) {
      console.error('Rejection error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to reject request.', type: 'error' });
    } finally {
      setActionLoadingId(null);
    }
  };

  // Toggle Account Active status (Employee)
  const handleToggleStatus = async (id: string, currentActive: boolean) => {
    setMessage(null);
    setActionLoadingId(id);
    try {
      const nextStatus = currentActive ? 'DEACTIVE' : 'ACTIVE';
      const res = await api.patch(`/employees/${id}/status`, { status: nextStatus });
      setMessage({ text: res.data.message || `Account successfully ${currentActive ? 'deactivated' : 'activated'}.`, type: 'success' });
      fetchUsers();
    } catch (err: any) {
      console.error('Toggle status error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to toggle account state.', type: 'error' });
    } finally {
      setActionLoadingId(null);
    }
  };

  // Toggle Account Active status (Standard Admin)
  const handleToggleAdminStatus = async (id: string, currentActive: boolean) => {
    setMessage(null);
    setActionLoadingId(id);
    try {
      const nextStatus = currentActive ? 'DEACTIVE' : 'ACTIVE';
      const res = await api.patch(`/admin/${id}/status`, { status: nextStatus });
      setMessage({ text: res.data.message || `Admin status successfully ${currentActive ? 'deactivated' : 'activated'}.`, type: 'success' });
      fetchUsers();
    } catch (err: any) {
      console.error('Toggle admin status error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to toggle admin state.', type: 'error' });
    } finally {
      setActionLoadingId(null);
    }
  };

  // Local lists filters
  const filteredEmployees = employees.filter(emp => 
    emp.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    emp.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (emp.department && emp.department.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  const filteredAdmins = admins.filter(adm => 
    adm.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    adm.email.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="employee-mgmt-container fade-in">
      <header className="employee-mgmt-header">
        <div>
          <h1>User Directory Management</h1>
          <p className="subtitle">Configure settings and account approvals for employees and administrators.</p>
        </div>
        
        {activeTab === 'admins' ? (
          <button 
            className="btn btn-primary"
            onClick={() => {
              setShowAddAdminModal(true);
              setAdmErrors({});
              setMessage(null);
            }}
          >
            <UserPlus size={20} />
            <span>Create Admin</span>
          </button>
        ) : (
          <button 
            className="btn btn-primary"
            onClick={() => {
              setShowAddEmployeeModal(true);
              setEmpErrors({});
              setMessage(null);
            }}
          >
            <UserPlus size={20} />
            <span>Register Employee</span>
          </button>
        )}
      </header>

      {message && (
        <div className={`employee-alert alert-${message.type === 'success' ? 'success' : 'danger'}`}>
          {message.type === 'success' ? <CheckCircle size={20} /> : <XCircle size={20} />}
          <span>{message.text}</span>
        </div>
      )}

      {/* Database Listing Panel */}
      <div className="employee-list-section glass-card">
        <div className="list-controls-bar">
          {/* Search box */}
          <div className="search-box-wrapper">
            <Search className="search-icon" size={18} />
            <input 
              type="text" 
              placeholder={`Search in ${activeTab === 'admins' ? 'admins' : 'employees'}...`}
              className="search-input"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          {/* Tab buttons */}
          <div className="tab-buttons">
            <button 
              className={`tab-btn ${activeTab === 'approved' ? 'active' : ''}`}
              onClick={() => {
                setActiveTab('approved');
                setSearchQuery('');
              }}
            >
              <Users size={16} />
              <span>Active Employees</span>
            </button>
            
            <button 
              className={`tab-btn ${activeTab === 'pending' ? 'active' : ''}`}
              onClick={() => {
                setActiveTab('pending');
                setSearchQuery('');
              }}
            >
              <AlertCircle size={16} />
              <span>Pending Approvals</span>
            </button>

            {isSuperAdmin && (
              <button 
                className={`tab-btn ${activeTab === 'admins' ? 'active' : ''}`}
                onClick={() => {
                  setActiveTab('admins');
                  setSearchQuery('');
                }}
              >
                <ShieldCheck size={16} />
                <span>Administrators</span>
              </button>
            )}
          </div>
        </div>

        {loading ? (
          <div className="table-loading">
            <div className="custom-spinner" />
            <p>SYNCING DATABASE REGISTERS...</p>
          </div>
        ) : activeTab === 'admins' ? (
          /* Administrators View */
          filteredAdmins.length > 0 ? (
            <div className="employee-logs-container">
              {/* Desktop Table View */}
              <div className="table-responsive hide-on-mobile">
                <table className="employee-table">
                  <thead>
                    <tr>
                      <th>Admin Name</th>
                      <th>Email Address</th>
                      <th>Role Level</th>
                      <th>Status</th>
                      <th className="center-cell">Status Toggle</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredAdmins.map((adm) => (
                      <tr key={adm._id}>
                        <td className="emp-name-cell">
                          <div className="avatar-circle avatar-admin">
                            {adm.name.charAt(0).toUpperCase()}
                          </div>
                          <div className="emp-info-cell">
                            <strong>{adm.name}</strong>
                          </div>
                        </td>
                        <td>{adm.email}</td>
                        <td>
                          <span className={`badge ${adm.role === 'SUPER_ADMIN' ? 'badge-info' : 'badge-success'}`}>
                            {adm.role}
                          </span>
                        </td>
                        <td>
                          <span className={`badge ${adm.isActive !== false ? 'badge-success' : 'badge-danger'}`}>
                            {adm.isActive !== false ? 'ACTIVE' : 'DEACTIVATED'}
                          </span>
                        </td>
                        <td className="center-cell actions-cell">
                          {adm._id === user?._id || adm.role === 'SUPER_ADMIN' ? (
                            <span className="text-muted italic">—</span>
                          ) : (
                            <button 
                              className={`action-btn-circle toggle-status-btn ${adm.isActive !== false ? 'active-state' : 'inactive-state'}`} 
                              title={adm.isActive !== false ? 'Deactivate Admin' : 'Activate Admin'}
                              onClick={() => handleToggleAdminStatus(adm._id, adm.isActive !== false)}
                              disabled={actionLoadingId === adm._id}
                            >
                              <Power size={16} />
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Mobile Card List View */}
              <div className="mobile-cards-list show-on-mobile">
                {filteredAdmins.map((adm) => (
                  <div key={adm._id} className="mobile-log-card glass-card">
                    <div className="card-row-header">
                      <div className="emp-avatar-row">
                        <div className="avatar-circle avatar-admin">
                          {adm.name.charAt(0).toUpperCase()}
                        </div>
                        <div className="emp-details">
                          <strong>{adm.name}</strong>
                          <span className="badge badge-info margin-top-025rem">{adm.role}</span>
                        </div>
                      </div>
                      <span className={`badge ${adm.isActive !== false ? 'badge-success' : 'badge-danger'}`}>
                        {adm.isActive !== false ? 'ACTIVE' : 'DEACTIVATED'}
                      </span>
                    </div>
                    
                    <div className="card-row-details">
                      <div className="detail-item">
                        <span className="detail-lbl">Email Address</span>
                        <span className="detail-val">{adm.email}</span>
                      </div>
                    </div>
                    
                    {adm._id !== user?._id && adm.role !== 'SUPER_ADMIN' && (
                      <div className="card-row-actions">
                        <button 
                          className={`btn btn-secondary w-full toggle-status-btn-mobile ${adm.isActive !== false ? 'active-state' : 'inactive-state'}`}
                          onClick={() => handleToggleAdminStatus(adm._id, adm.isActive !== false)}
                          disabled={actionLoadingId === adm._id}
                        >
                          <Power size={14} />
                          <span>{adm.isActive !== false ? 'Deactivate' : 'Activate'}</span>
                        </button>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <p className="text-muted padding-2rem text-center">No matching administrators found.</p>
          )
        ) : (
          /* Employees View */
          filteredEmployees.length > 0 ? (
            <div className="employee-logs-container">
              {/* Desktop Table View */}
              <div className="table-responsive hide-on-mobile">
                <table className="employee-table">
                  <thead>
                    <tr>
                      <th>Employee Name</th>
                      <th>Email Address</th>
                      <th>Department</th>
                      <th>Account Status</th>
                      <th className="center-cell">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredEmployees.map((emp) => (
                      <tr key={emp._id}>
                        <td className="emp-name-cell">
                          <div className="avatar-circle">
                            {emp.name.charAt(0).toUpperCase()}
                          </div>
                          <div className="emp-info-cell">
                            <strong>{emp.name}</strong>
                          </div>
                        </td>
                        <td>{emp.email}</td>
                        <td>
                          <span className="dept-tag">{emp.department || '—'}</span>
                        </td>
                        <td>
                          {activeTab === 'pending' ? (
                            <span className="badge badge-warning">Awaiting Approval</span>
                          ) : (
                            <span className={`badge ${emp.isActive !== false ? 'badge-success' : 'badge-danger'}`}>
                              {emp.isActive !== false ? 'ACTIVE' : 'DEACTIVATED'}
                            </span>
                          )}
                        </td>
                        <td className="center-cell actions-cell">
                          {activeTab === 'pending' ? (
                            <div className="btn-action-group">
                              <button 
                                className="action-btn-circle approve-btn" 
                                title="Approve employee"
                                onClick={() => handleApprove(emp._id)}
                                disabled={actionLoadingId === emp._id}
                              >
                                <Check size={16} />
                              </button>
                              <button 
                                className="action-btn-circle reject-btn" 
                                title="Reject employee"
                                onClick={() => handleReject(emp._id)}
                                disabled={actionLoadingId === emp._id}
                              >
                                <X size={16} />
                              </button>
                            </div>
                          ) : (
                            <div className="btn-action-group">
                              <button 
                                className="action-btn-circle edit-btn" 
                                title="Edit Employee details"
                                onClick={() => openEditModal(emp)}
                              >
                                <Edit2 size={16} />
                              </button>
                              
                              <button 
                                className={`action-btn-circle toggle-status-btn ${emp.isActive !== false ? 'active-state' : 'inactive-state'}`} 
                                title={emp.isActive !== false ? 'Deactivate Account' : 'Activate Account'}
                                onClick={() => handleToggleStatus(emp._id, emp.isActive !== false)}
                                disabled={actionLoadingId === emp._id}
                              >
                                <Power size={16} />
                              </button>
                            </div>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Mobile Card List View */}
              <div className="mobile-cards-list show-on-mobile">
                {filteredEmployees.map((emp) => (
                  <div key={emp._id} className="mobile-log-card glass-card">
                    <div className="card-row-header">
                      <div className="emp-avatar-row">
                        <div className="avatar-circle">
                          {emp.name.charAt(0).toUpperCase()}
                        </div>
                        <div className="emp-details">
                          <strong>{emp.name}</strong>
                          <span className="dept-tag margin-top-025rem">{emp.department || 'No Dept'}</span>
                        </div>
                      </div>
                      
                      {activeTab === 'pending' ? (
                        <span className="badge badge-warning">Awaiting Approval</span>
                      ) : (
                        <span className={`badge ${emp.isActive !== false ? 'badge-success' : 'badge-danger'}`}>
                          {emp.isActive !== false ? 'ACTIVE' : 'DEACTIVATED'}
                        </span>
                      )}
                    </div>
                    
                    <div className="card-row-details">
                      <div className="detail-item">
                        <span className="detail-lbl">Email Address</span>
                        <span className="detail-val">{emp.email}</span>
                      </div>
                    </div>
                    
                    <div className="card-row-actions gap-05rem">
                      {activeTab === 'pending' ? (
                        <>
                          <button 
                            className="btn btn-success flex-1" 
                            onClick={() => handleApprove(emp._id)}
                            disabled={actionLoadingId === emp._id}
                          >
                            <Check size={14} />
                            <span>Approve</span>
                          </button>
                          <button 
                            className="btn btn-danger flex-1" 
                            onClick={() => handleReject(emp._id)}
                            disabled={actionLoadingId === emp._id}
                          >
                            <X size={14} />
                            <span>Reject</span>
                          </button>
                        </>
                      ) : (
                        <>
                          <button 
                            className="btn btn-secondary flex-1" 
                            onClick={() => openEditModal(emp)}
                          >
                            <Edit2 size={14} />
                            <span>Edit</span>
                          </button>
                          
                          <button 
                            className={`btn btn-secondary flex-1 toggle-status-btn-mobile ${emp.isActive !== false ? 'active-state' : 'inactive-state'}`} 
                            onClick={() => handleToggleStatus(emp._id, emp.isActive !== false)}
                            disabled={actionLoadingId === emp._id}
                          >
                            <Power size={14} />
                            <span>{emp.isActive !== false ? 'Deactivate' : 'Activate'}</span>
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <p className="text-muted padding-2rem text-center">
              {searchQuery ? 'No matching employee records found.' : `No employee records found.`}
            </p>
          )
        )}
      </div>

      {/* Modal 1: Register Employee overlay */}
      {showAddEmployeeModal && (
        <div className="modal-backdrop">
          <div className="modal-box glass-card fade-in">
            <div className="modal-header">
              <h3>Direct Employee Registration</h3>
              <button className="modal-close-btn" onClick={() => setShowAddEmployeeModal(false)}>&times;</button>
            </div>
            
            <form onSubmit={handleCreateEmployeeSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Full Name</label>
                  <input 
                    type="text" 
                    className={`form-input ${empErrors.name ? 'input-error' : ''}`}
                    placeholder="e.g. Adarsh Kumar"
                    value={empName}
                    onChange={(e) => setEmpName(e.target.value)}
                    required
                  />
                  {empErrors.name && <span className="validation-error">{empErrors.name}</span>}
                </div>

                <div className="form-group">
                  <label className="form-label">Email Address</label>
                  <input 
                    type="email" 
                    className={`form-input ${empErrors.email ? 'input-error' : ''}`}
                    placeholder="Email"
                    value={empEmail}
                    onChange={(e) => setEmpEmail(e.target.value)}
                    autoComplete="off"
                    required
                  />
                  {empErrors.email && <span className="validation-error">{empErrors.email}</span>}
                </div>

                <div className="form-group">
                  <label className="form-label">Temporary Password</label>
                  <input 
                    type="password" 
                    className={`form-input ${empErrors.password ? 'input-error' : ''}`}
                    placeholder="Password"
                    value={empPassword}
                    onChange={(e) => setEmpPassword(e.target.value)}
                    autoComplete="new-password"
                    required
                  />
                  <span className="input-helper-text">Requirement: At least 6 characters.</span>
                  {empErrors.password && <span className="validation-error">{empErrors.password}</span>}
                </div>

                <div className="form-group">
                  <label className="form-label">Department</label>
                  <input 
                    type="text" 
                    className={`form-input ${empErrors.department ? 'input-error' : ''}`}
                    placeholder="e.g. Sales, Marketing"
                    value={empDept}
                    onChange={(e) => setEmpDept(e.target.value)}
                    required
                  />
                  {empErrors.department && <span className="validation-error">{empErrors.department}</span>}
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowAddEmployeeModal(false)} disabled={modalSubmitting}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={modalSubmitting}>
                  {modalSubmitting ? 'Creating Employee...' : 'Create Employee'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal 2: Edit Employee Details overlay */}
      {editingEmployee && (
        <div className="modal-backdrop">
          <div className="modal-box glass-card fade-in">
            <div className="modal-header">
              <h3>Edit Employee Details</h3>
              <button className="modal-close-btn" onClick={() => setEditingEmployee(null)}>&times;</button>
            </div>
            
            <form onSubmit={handleEditEmployeeSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Full Name</label>
                  <input 
                    type="text" 
                    className={`form-input ${editErrors.name ? 'input-error' : ''}`}
                    value={editName}
                    onChange={(e) => setEditName(e.target.value)}
                    required
                  />
                  {editErrors.name && <span className="validation-error">{editErrors.name}</span>}
                </div>

                <div className="form-group">
                  <label className="form-label">Email Address</label>
                  <input 
                    type="email" 
                    className={`form-input ${editErrors.email ? 'input-error' : ''}`}
                    value={editEmail}
                    onChange={(e) => setEditEmail(e.target.value)}
                    required
                  />
                  {editErrors.email && <span className="validation-error">{editErrors.email}</span>}
                </div>

                <div className="form-group">
                  <label className="form-label">Department</label>
                  <input 
                    type="text" 
                    className={`form-input ${editErrors.department ? 'input-error' : ''}`}
                    value={editDept}
                    onChange={(e) => setEditDept(e.target.value)}
                    required
                  />
                  {editErrors.department && <span className="validation-error">{editErrors.department}</span>}
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setEditingEmployee(null)} disabled={modalSubmitting}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={modalSubmitting}>
                  {modalSubmitting ? 'Saving Changes...' : 'Save Changes'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal 3: Register Admin overlay */}
      {showAddAdminModal && (
        <div className="modal-backdrop">
          <div className="modal-box glass-card fade-in">
            <div className="modal-header">
              <h3>Create Administrator Account</h3>
              <button className="modal-close-btn" onClick={() => setShowAddAdminModal(false)}>&times;</button>
            </div>
            
            <form onSubmit={handleCreateAdminSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Admin Name</label>
                  <input 
                    type="text" 
                    className={`form-input ${admErrors.name ? 'input-error' : ''}`}
                    placeholder="e.g. Sneha Nair"
                    value={admName}
                    onChange={(e) => setAdmName(e.target.value)}
                    required
                  />
                  {admErrors.name && <span className="validation-error">{admErrors.name}</span>}
                </div>

                <div className="form-group">
                  <label className="form-label">Email Address</label>
                  <input 
                    type="email" 
                    className={`form-input ${admErrors.email ? 'input-error' : ''}`}
                    placeholder="Email"
                    value={admEmail}
                    onChange={(e) => setAdmEmail(e.target.value)}
                    autoComplete="off"
                    required
                  />
                  {admErrors.email && <span className="validation-error">{admErrors.email}</span>}
                </div>

                <div className="form-group">
                  <label className="form-label">Secure Password</label>
                  <input 
                    type="password" 
                    className={`form-input ${admErrors.password ? 'input-error' : ''}`}
                    placeholder="Password"
                    value={admPassword}
                    onChange={(e) => setAdmPassword(e.target.value)}
                    autoComplete="new-password"
                    required
                  />
                  <span className="input-helper-text">Requirement: At least 6 characters.</span>
                  {admErrors.password && <span className="validation-error">{admErrors.password}</span>}
                </div>

                <div className="form-group">
                  <label className="form-label">Role Classification</label>
                  <select 
                    className="form-select"
                    value={admRole}
                    onChange={(e) => setAdmRole(e.target.value as any)}
                    required
                  >
                    <option value="ADMIN">Standard Administrator (ADMIN)</option>
                    <option value="SUPER_ADMIN">Root Administrator (SUPER_ADMIN)</option>
                  </select>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowAddAdminModal(false)} disabled={modalSubmitting}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={modalSubmitting}>
                  {modalSubmitting ? 'Creating Account...' : 'Create Account'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default EmployeeManagement;
