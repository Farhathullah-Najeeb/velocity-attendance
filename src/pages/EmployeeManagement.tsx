import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import SkeletonLoader from '../components/SkeletonLoader';
import EmptyState from '../components/EmptyState';
import ConfirmModal from '../components/ConfirmModal';
import type { IUser, IRole, ISite } from '../types';
import { 
  UserPlus, 
  Search, 
  Users, 
  AlertCircle, 
  ShieldCheck, 
  Check, 
  X, 
  Edit2, 
  Power,
  Trash2,
  Plus,
  Settings
} from 'lucide-react';
import './EmployeeManagement.css';

const EmployeeManagement: React.FC = () => {
  const { user } = useAuth();
  const isSuperAdmin = user?.role === 'SUPER_ADMIN';

  // Employees lists
  const [employees, setEmployees] = useState<IUser[]>([]);
  const [admins, setAdmins] = useState<IUser[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Tab control: 'approved' | 'pending' | 'admins' | 'roles'
  const [activeTab, setActiveTab] = useState<'approved' | 'pending' | 'admins' | 'roles'>('approved');
  const [searchQuery, setSearchQuery] = useState('');

  // Custom Roles & Permissions states
  const [customRoles, setCustomRoles] = useState<IRole[]>([]);
  const [systemPermissions, setSystemPermissions] = useState<string[]>([]);
  
  // Custom Role Creator/Editor form inputs
  const [showRoleModal, setShowRoleModal] = useState(false);
  const [selectedRole, setSelectedRole] = useState<IRole | null>(null);
  const [roleName, setRoleName] = useState('');
  const [roleDesc, setRoleDesc] = useState('');
  const [selectedPermissions, setSelectedPermissions] = useState<string[]>([]);

  // Assign user roles and permissions inputs
  const [assignUser, setAssignUser] = useState<IUser | null>(null);
  const [targetRoleId, setTargetRoleId] = useState('');
  const [targetPermissions, setTargetPermissions] = useState<string[]>([]);

  // Modals status
  const [showAddEmployeeModal, setShowAddEmployeeModal] = useState(false);
  const [showAddAdminModal, setShowAddAdminModal] = useState(false);
  const [editingEmployee, setEditingEmployee] = useState<IUser | null>(null);
  const [sites, setSites] = useState<ISite[]>([]);
  const [editSiteId, setEditSiteId] = useState<string>('');

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

  const { showToast } = useToast();
  // We keep `setMessage` as a wrapper to avoid rewriting 30 lines
  const setMessage = (msg: { text: string; type: 'success' | 'error' | 'info' } | null) => {
    if (msg) {
      showToast(msg.text, msg.type);
    }
  };

  const [confirmModal, setConfirmModal] = useState<{ isOpen: boolean; title: string; message: string; onConfirm: () => void; isDestructive: boolean }>({
    isOpen: false, title: '', message: '', onConfirm: () => {}, isDestructive: true
  });

  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [modalSubmitting, setModalSubmitting] = useState(false);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      if (activeTab === 'admins') {
        const res = await api.get<IUser[]>('/admin/list');
        setAdmins(res.data);
      } else if (activeTab === 'roles') {
        const [rolesRes, permRes] = await Promise.all([
          api.get<IRole[]>('/roles'),
          api.get<string[]>('/admin/permissions')
        ]);
        setCustomRoles(rolesRes.data);
        setSystemPermissions(permRes.data);
      } else {
        const status = activeTab === 'pending' ? 'PENDING' : 'APPROVED';
        const res = await api.get<IUser[]>('/employees', {
          params: { status }
        });
        setEmployees(res.data);
      api.get<ISite[]>('/sites').then(r => setSites(r.data || [])).catch(() => {});
      }
    } catch (err) {
      console.error('Error fetching users:', err);
      setMessage({ text: 'Failed to retrieve user registry.', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  // Fetch custom roles list on load so they are available for assignment dropdowns
  const fetchInitialRoles = async () => {
    try {
      const res = await api.get<IRole[]>('/roles');
      setCustomRoles(res.data);
    } catch (err) {
      console.error('Error fetching initial roles:', err);
    }
  };

  useEffect(() => {
    fetchUsers();
    fetchInitialRoles();
  }, [activeTab]);

  // Body scroll lock: prevent page scrolling while any modal is open
  useEffect(() => {
    const isAnyModalOpen = showAddEmployeeModal || showAddAdminModal || showRoleModal || assignUser !== null;
    if (isAnyModalOpen) {
      document.body.classList.add('modal-open');
    } else {
      document.body.classList.remove('modal-open');
    }
    return () => {
      document.body.classList.remove('modal-open');
    };
  }, [showAddEmployeeModal, showAddAdminModal, showRoleModal, assignUser]);



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

  // Open custom role modal for creating or editing
  const openRoleModal = (role: IRole | null = null) => {
    setSelectedRole(role);
    if (role) {
      setRoleName(role.name);
      setRoleDesc(role.description || '');
      setSelectedPermissions(role.permissions || []);
    } else {
      setRoleName('');
      setRoleDesc('');
      setSelectedPermissions([]);
    }
    setShowRoleModal(true);
  };

  // Handle Custom Role submit (Create or Edit)
  const handleRoleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!roleName.trim()) return;

    setModalSubmitting(true);
    setMessage(null);
    try {
      if (selectedRole) {
        // Edit Role
        const res = await api.patch(`/roles/${selectedRole._id}`, {
          name: roleName.trim(),
          description: roleDesc.trim(),
          permissions: selectedPermissions
        });
        setMessage({ text: res.data.message || 'Custom role updated successfully.', type: 'success' });
      } else {
        // Create Role
        const res = await api.post('/roles', {
          name: roleName.trim(),
          description: roleDesc.trim(),
          permissions: selectedPermissions
        });
        setMessage({ text: res.data.message || 'Custom role registered successfully.', type: 'success' });
      }
      setShowRoleModal(false);
      setSelectedRole(null);
      setRoleName('');
      setRoleDesc('');
      setSelectedPermissions([]);
      fetchUsers();
    } catch (err: any) {
      console.error('Role submit error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to save custom role.', type: 'error' });
    } finally {
      setModalSubmitting(false);
    }
  };

  // Handle delete custom role
  const handleDeleteRole = (id: string) => {
    setConfirmModal({
      isOpen: true,
      title: 'Delete Custom Role',
      message: 'Are you sure you want to delete this custom role? This will clear role assignments for related users.',
      isDestructive: true,
      onConfirm: async () => {
        setMessage(null);
        setActionLoadingId(id);
        try {
          const res = await api.delete(`/roles/${id}`);
          setMessage({ text: res.data.message || 'Custom role removed successfully.', type: 'success' });
          fetchUsers();
        } catch (err: any) {
          console.error('Delete role error:', err);
          setMessage({ text: err.response?.data?.message || 'Failed to remove custom role.', type: 'error' });
        } finally {
          setActionLoadingId(null);
        }
      }
    });
  };

  // Handle Employee role update assignment
  const handleAssignEmployeeRoleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!assignUser) return;

    setModalSubmitting(true);
    setMessage(null);
    try {
      const res = await api.patch(`/employees/${assignUser._id}/role`, {
        roleId: targetRoleId || null
      });
      setMessage({ text: res.data.message || 'Employee role updated successfully.', type: 'success' });
      setAssignUser(null);
      fetchUsers();
    } catch (err: any) {
      console.error('Assign employee role error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to assign role to employee.', type: 'error' });
    } finally {
      setModalSubmitting(false);
    }
  };

  // Handle Admin role & granular permissions update assignment
  const handleAssignAdminCredentialsSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!assignUser) return;

    setModalSubmitting(true);
    setMessage(null);
    try {
      // 1. Assign role
      await api.patch(`/admin/${assignUser._id}/role`, {
        roleId: targetRoleId || null
      });

      // 2. Assign granular permissions
      const res = await api.patch(`/admin/${assignUser._id}/permissions`, {
        permissions: targetPermissions
      });

      setMessage({ text: res.data.message || 'Admin role and system permissions updated.', type: 'success' });
      setAssignUser(null);
      fetchUsers();
    } catch (err: any) {
      console.error('Assign admin credentials error:', err);
      setMessage({ text: err.response?.data?.message || 'Failed to update administrator credentials.', type: 'error' });
    } finally {
      setModalSubmitting(false);
    }
  };

  // Toggle checklist permission selection
  const handleTogglePermissionSelection = (perm: string) => {
    if (selectedPermissions.includes(perm)) {
      setSelectedPermissions(selectedPermissions.filter(p => p !== perm));
    } else {
      setSelectedPermissions([...selectedPermissions, perm]);
    }
  };

  const handleToggleTargetPermissionSelection = (perm: string) => {
    if (targetPermissions.includes(perm)) {
      setTargetPermissions(targetPermissions.filter(p => p !== perm));
    } else {
      setTargetPermissions([...targetPermissions, perm]);
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
  const handleReject = (id: string) => {
    setConfirmModal({
      isOpen: true,
      title: 'Reject Registration',
      message: 'Are you sure you want to reject this employee registration? This will permanently delete their account.',
      isDestructive: true,
      onConfirm: async () => {
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
      }
    });
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
        ) : activeTab === 'roles' ? (
          <button 
            className="btn btn-primary"
            onClick={() => {
              openRoleModal(null);
              setMessage(null);
            }}
          >
            <Plus size={20} />
            <span>Create Role</span>
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

      {/* Confirmation Modal */}
      <ConfirmModal
        isOpen={confirmModal.isOpen}
        title={confirmModal.title}
        message={confirmModal.message}
        onConfirm={() => {
          confirmModal.onConfirm();
          setConfirmModal(prev => ({ ...prev, isOpen: false }));
        }}
        onCancel={() => setConfirmModal(prev => ({ ...prev, isOpen: false }))}
        isDestructive={confirmModal.isDestructive}
      />

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
              <>
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

                <button 
                  className={`tab-btn ${activeTab === 'roles' ? 'active' : ''}`}
                  onClick={() => {
                    setActiveTab('roles');
                    setSearchQuery('');
                  }}
                >
                  <Settings size={16} />
                  <span>Custom Roles</span>
                </button>
              </>
            )}
          </div>
        </div>

        {loading ? (
          <SkeletonLoader type="table" count={5} />
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
                            <div className="btn-action-group">
                              <button 
                                type="button"
                                className="action-btn-circle role-btn" 
                                title="Manage custom role & permissions"
                                onClick={() => {
                                  setAssignUser(adm);
                                  setTargetRoleId(adm.customRole?._id || '');
                                  setTargetPermissions(adm.permissions || []);
                                }}
                              >
                                <ShieldCheck size={16} />
                              </button>

                              <button 
                                type="button"
                                className={`action-btn-circle toggle-status-btn ${adm.isActive !== false ? 'active-state' : 'inactive-state'}`} 
                                title={adm.isActive !== false ? 'Deactivate Admin' : 'Activate Admin'}
                                onClick={() => handleToggleAdminStatus(adm._id, adm.isActive !== false)}
                                disabled={actionLoadingId === adm._id}
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
                      <div className="card-row-actions gap-05rem">
                        <button 
                          type="button"
                          className="btn btn-secondary flex-1"
                          onClick={() => {
                            setAssignUser(adm);
                            setTargetRoleId(adm.customRole?._id || '');
                            setTargetPermissions(adm.permissions || []);
                          }}
                        >
                          <ShieldCheck size={14} />
                          <span>Credentials</span>
                        </button>
                        
                        <button 
                          type="button"
                          className={`btn btn-secondary flex-1 toggle-status-btn-mobile ${adm.isActive !== false ? 'active-state' : 'inactive-state'}`}
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
            <EmptyState 
              title="No Administrators Found" 
              description="There are no active administrators matching your search criteria." 
            />
          )
        ) : activeTab === 'roles' ? (
          /* Custom Roles View */
          customRoles.length > 0 ? (
            <div className="custom-roles-tab-section">
              <div className="roles-cards-grid">
                {customRoles.map((role) => (
                  <div className="role-card glass-card" key={role._id}>
                    <div className="role-card-header">
                      <h3>{role.name}</h3>
                      <div className="btn-action-group">
                        <button 
                          type="button"
                          className="action-btn-circle edit-btn" 
                          title="Edit Custom Role"
                          onClick={() => openRoleModal(role)}
                        >
                          <Edit2 size={14} />
                        </button>
                        <button 
                          type="button"
                          className="action-btn-circle reject-btn" 
                          title="Delete Custom Role"
                          onClick={() => handleDeleteRole(role._id)}
                          disabled={actionLoadingId === role._id}
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </div>
                    <p className="role-desc">{role.description || 'No description provided.'}</p>
                    <div className="role-permissions-list">
                      <h4>Permissions</h4>
                      <div className="permissions-tags-row">
                        {role.permissions && role.permissions.length > 0 ? (
                          role.permissions.map((perm) => (
                            <span key={perm} className="permission-tag-badge">
                              {perm}
                            </span>
                          ))
                        ) : (
                          <span className="text-muted italic text-xs">No permissions assigned.</span>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <p className="text-muted padding-2rem text-center">No custom roles created yet.</p>
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
                          <div className="emp-dept-role-container">
                            <span className="dept-tag">{emp.department || '—'}</span>
                            {emp.customRole && (
                              <span className="custom-role-badge">
                                {emp.customRole.name}
                              </span>
                            )}
                          </div>
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
                                type="button"
                                className="action-btn-circle approve-btn" 
                                title="Approve employee"
                                onClick={() => handleApprove(emp._id)}
                                disabled={actionLoadingId === emp._id}
                              >
                                <Check size={16} />
                              </button>
                              <button 
                                type="button"
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
                                type="button"
                                className="action-btn-circle edit-btn" 
                                title="Edit Employee details"
                                onClick={() => openEditModal(emp)}
                              >
                                <Edit2 size={16} />
                              </button>

                              <button 
                                type="button"
                                className="action-btn-circle role-btn" 
                                title="Assign custom role"
                                onClick={() => {
                                  setAssignUser(emp);
                                  setTargetRoleId(emp.customRole?._id || '');
                                }}
                              >
                                <ShieldCheck size={16} />
                              </button>
                              
                              <button 
                                type="button"
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
                          <div className="emp-dept-role-container margin-top-025rem">
                            <span className="dept-tag">{emp.department || 'No Dept'}</span>
                            {emp.customRole && (
                              <span className="custom-role-badge">
                                {emp.customRole.name}
                              </span>
                            )}
                          </div>
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
                            type="button"
                            className="btn btn-success flex-1" 
                            onClick={() => handleApprove(emp._id)}
                            disabled={actionLoadingId === emp._id}
                          >
                            <Check size={14} />
                            <span>Approve</span>
                          </button>
                          <button 
                            type="button"
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
                            type="button"
                            className="btn btn-secondary flex-1" 
                            onClick={() => openEditModal(emp)}
                          >
                            <Edit2 size={14} />
                            <span>Edit</span>
                          </button>

                          <button 
                            type="button"
                            className="btn btn-secondary flex-1" 
                            onClick={() => {
                              setAssignUser(emp);
                              setTargetRoleId(emp.customRole?._id || '');
                            }}
                          >
                            <ShieldCheck size={14} />
                            <span>Role</span>
                          </button>
                          
                          <button 
                            type="button"
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
            <EmptyState 
              title="No Employees Found" 
              description={searchQuery ? "No matching employee records found." : "No employee records found."} 
            />
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

                  <div className="form-group margin-top-1rem">
                    <label className="form-label">Assigned Work Site Location</label>
                    <select
                      className="form-input"
                      value={editSiteId}
                      onChange={(e) => setEditSiteId(e.target.value)}
                    >
                      <option value="">Main Office (Default)</option>
                      {sites.map(s => (
                        <option key={s._id} value={s._id}>{s.name} ({s.address || 'Geofenced'})</option>
                      ))}
                    </select>
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

      {/* Modal 4: Custom Role Creator/Editor overlay */}
      {showRoleModal && (
        <div className="modal-backdrop">
          <div className="modal-box modal-box-lg glass-card fade-in">
            <div className="modal-header">
              <h3>{selectedRole ? 'Edit Custom Role' : 'Create Custom Role'}</h3>
              <button type="button" className="modal-close-btn" onClick={() => setShowRoleModal(false)}>&times;</button>
            </div>
            
            <form onSubmit={handleRoleSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Role Name (Identifier)</label>
                  <input 
                    type="text" 
                    className="form-input"
                    placeholder="e.g. HR_OFFICER"
                    value={roleName}
                    onChange={(e) => setRoleName(e.target.value.toUpperCase().replace(/\s+/g, '_'))}
                    required
                    disabled={!!selectedRole}
                  />
                  <span className="input-helper-text">Uppercase with underscores. Cannot be edited once created.</span>
                </div>

                <div className="form-group">
                  <label className="form-label">Role Description</label>
                  <textarea 
                    className="form-input form-textarea"
                    placeholder="e.g. Manage employee directories and leave schedules."
                    value={roleDesc}
                    onChange={(e) => setRoleDesc(e.target.value)}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label font-bold">Select Role Permissions</label>
                  {systemPermissions.length > 0 ? (
                    <div className="permissions-checklist-grid">
                      {systemPermissions.map((perm) => (
                        <label key={perm} className="permission-checkbox-label">
                          <input 
                            type="checkbox"
                            checked={selectedPermissions.includes(perm)}
                            onChange={() => handleTogglePermissionSelection(perm)}
                          />
                          <span className="checkbox-custom" />
                          <span className="permission-name-text">{perm.replace(/_/g, ' ')}</span>
                        </label>
                      ))}
                    </div>
                  ) : (
                    <p className="text-muted italic">Loading system permissions...</p>
                  )}
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowRoleModal(false)} disabled={modalSubmitting}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={modalSubmitting}>
                  {modalSubmitting ? 'Saving Role...' : selectedRole ? 'Save Changes' : 'Create Role'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal 5: Assign Employee Role overlay */}
      {assignUser && assignUser.role === 'EMPLOYEE' && (
        <div className="modal-backdrop">
          <div className="modal-box glass-card fade-in">
            <div className="modal-header">
              <h3>Assign Custom Role to Employee</h3>
              <button type="button" className="modal-close-btn" onClick={() => setAssignUser(null)}>&times;</button>
            </div>
            
            <form onSubmit={handleAssignEmployeeRoleSubmit}>
              <div className="modal-body">
                <p className="modal-info-text">
                  Assigning a custom role to <strong>{assignUser.name}</strong> will grant them permissions defined within that role.
                </p>

                <div className="form-group">
                  <label className="form-label">Select Custom Role</label>
                  <select 
                    className="form-select"
                    value={targetRoleId}
                    onChange={(e) => setTargetRoleId(e.target.value)}
                  >
                    <option value="">No Role / Default Employee</option>
                    {customRoles.map((role) => (
                      <option key={role._id} value={role._id}>
                        {role.name} ({role.description || 'No description'})
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setAssignUser(null)} disabled={modalSubmitting}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={modalSubmitting}>
                  {modalSubmitting ? 'Saving Role...' : 'Assign Role'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal 6: Assign Admin Role & Permissions overlay */}
      {assignUser && assignUser.role !== 'EMPLOYEE' && (
        <div className="modal-backdrop">
          <div className="modal-box modal-box-lg glass-card fade-in">
            <div className="modal-header">
              <h3>Manage Admin Role & Permissions</h3>
              <button type="button" className="modal-close-btn" onClick={() => setAssignUser(null)}>&times;</button>
            </div>
            
            <form onSubmit={handleAssignAdminCredentialsSubmit}>
              <div className="modal-body">
                <p className="modal-info-text">
                  Configure role assignment and granular permissions for administrator account <strong>{assignUser.name}</strong>.
                </p>

                <div className="form-group">
                  <label className="form-label">Select Custom Role</label>
                  <select 
                    className="form-select"
                    value={targetRoleId}
                    onChange={(e) => setTargetRoleId(e.target.value)}
                  >
                    <option value="">No Role / Default Admin</option>
                    {customRoles.map((role) => (
                      <option key={role._id} value={role._id}>
                        {role.name}
                      </option>
                    ))}
                  </select>
                  <span className="input-helper-text">Selecting a role sets default permissions, which can be customized below.</span>
                </div>

                <div className="form-group">
                  <label className="form-label font-bold">Select Granular Permissions</label>
                  {systemPermissions.length > 0 ? (
                    <div className="permissions-checklist-grid">
                      {systemPermissions.map((perm) => (
                        <label key={perm} className="permission-checkbox-label">
                          <input 
                            type="checkbox"
                            checked={targetPermissions.includes(perm)}
                            onChange={() => handleToggleTargetPermissionSelection(perm)}
                          />
                          <span className="checkbox-custom" />
                          <span className="permission-name-text">{perm.replace(/_/g, ' ')}</span>
                        </label>
                      ))}
                    </div>
                  ) : (
                    <p className="text-muted italic">Loading system permissions...</p>
                  )}
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setAssignUser(null)} disabled={modalSubmitting}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={modalSubmitting}>
                  {modalSubmitting ? 'Saving Credentials...' : 'Save Settings'}
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
