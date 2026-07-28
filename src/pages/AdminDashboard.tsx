import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';
import { 
  Users, 
  CalendarDays, 
  AlertTriangle, 
  Clock, 
  Calendar, 
  ChevronRight,
  TrendingUp,
  FileSpreadsheet,
  Settings,
  Compass
} from 'lucide-react';
import './AdminDashboard.css';

const AdminDashboard: React.FC = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState({
    totalEmployees: 0,
    pendingEmployees: 0,
    pendingLeaves: 0,
    pendingExceptions: 0,
  });
  const [loading, setLoading] = useState(true);
  const [systemTime, setSystemTime] = useState(new Date());

  // Tick clock
  useEffect(() => {
    const timer = setInterval(() => setSystemTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const fetchDashboardStats = async () => {
    setLoading(true);
    try {
      const [empAllRes, empPendingRes, leavesPendingRes, exceptionsPendingRes] = await Promise.all([
        api.get('/employees?status=APPROVED'),
        api.get('/employees?status=PENDING'),
        api.get('/leaves?status=PENDING'),
        api.get('/attendance/pending-approvals')
      ]);

      setStats({
        totalEmployees: empAllRes.data.length,
        pendingEmployees: empPendingRes.data.length,
        pendingLeaves: leavesPendingRes.data.length,
        pendingExceptions: exceptionsPendingRes.data.length,
      });
    } catch (err) {
      console.error('Error fetching dashboard statistics:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardStats();
  }, []);

  const shortcutLinks = [
    {
      title: 'Employee Approvals',
      desc: 'Review and approve pending registration requests.',
      count: stats.pendingEmployees,
      path: '/employees',
      icon: <Users size={24} className="shortcut-icon icon-blue" />,
      badgeColor: 'badge-blue'
    },
    {
      title: 'Leave Requests',
      desc: 'Process employee leave logs and balances.',
      count: stats.pendingLeaves,
      path: '/admin-leaves',
      icon: <CalendarDays size={24} className="shortcut-icon icon-purple" />,
      badgeColor: 'badge-purple'
    },
    {
      title: 'Attendance Exceptions',
      desc: 'Approve late arrivals or early checkouts.',
      count: stats.pendingExceptions,
      path: '/exceptions',
      icon: <AlertTriangle size={24} className="shortcut-icon icon-orange" />,
      badgeColor: 'badge-orange'
    },
    {
      title: 'Holidays & Settings',
      desc: 'Configure office hours, grace periods & holidays.',
      path: '/settings-holidays',
      icon: <Settings size={24} className="shortcut-icon icon-cyan" />,
    },
    {
      title: 'Attendance Reports',
      desc: 'Export monthly or weekly logs to PDF & Excel.',
      path: '/reports',
      icon: <FileSpreadsheet size={24} className="shortcut-icon icon-green" />,
    }
  ];

  return (
    <div className="admin-dashboard-container fade-in">
      <header className="dashboard-header">
        <div>
          <h1>Administrator Portal</h1>
          <p className="subtitle">Manage company operations, attendance rules, and leave applications.</p>
        </div>
        <div className="current-date-box glass-card">
          <Calendar className="date-icon" size={18} />
          <span>{systemTime.toLocaleDateString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</span>
        </div>
      </header>

      {loading ? (
        <div className="loader-container">
          <div className="custom-spinner" />
          <p>FETCHING CORE METRICS...</p>
        </div>
      ) : (
        <>
          {/* Quick Metrics Grid */}
          <div className="metrics-grid">
            <div className="metric-card glass-card border-blue">
              <div className="metric-header">
                <span className="metric-title">Approved Employees</span>
                <Users className="metric-icon icon-blue" size={20} />
              </div>
              <h2 className="metric-value">{stats.totalEmployees}</h2>
              <span className="metric-subtext">Active staff members</span>
            </div>

            <div className="metric-card glass-card border-yellow">
              <div className="metric-header">
                <span className="metric-title">Pending Employees</span>
                <Users className="metric-icon icon-yellow" size={20} />
              </div>
              <h2 className="metric-value">{stats.pendingEmployees}</h2>
              <span className="metric-subtext">Awaiting registration approval</span>
            </div>

            <div className="metric-card glass-card border-purple">
              <div className="metric-header">
                <span className="metric-title">Pending Leaves</span>
                <CalendarDays className="metric-icon icon-purple" size={20} />
              </div>
              <h2 className="metric-value">{stats.pendingLeaves}</h2>
              <span className="metric-subtext">Leave applications to review</span>
            </div>

            <div className="metric-card glass-card border-orange">
              <div className="metric-header">
                <span className="metric-title">Pending Exceptions</span>
                <AlertTriangle className="metric-icon icon-orange" size={20} />
              </div>
              <h2 className="metric-value">{stats.pendingExceptions}</h2>
              <span className="metric-subtext">Late-ins / early-outs pending review</span>
            </div>
          </div>

          <div className="admin-body-grid">
            {/* Navigation Grid */}
            <section className="shortcuts-section">
              <div className="section-title-wrapper">
                <TrendingUp size={20} className="section-title-icon" />
                <h3>Management Control Center</h3>
              </div>
              <div className="shortcuts-grid">
                {shortcutLinks.map((link, idx) => (
                  <div 
                    key={idx} 
                    className="shortcut-card glass-card"
                    onClick={() => navigate(link.path)}
                  >
                    <div className="shortcut-main">
                      {link.icon}
                      <div className="shortcut-info">
                        <h4>{link.title}</h4>
                        <p>{link.desc}</p>
                      </div>
                    </div>

                    <div className="shortcut-action">
                      {link.count !== undefined && link.count > 0 && (
                        <span className={`shortcut-badge ${link.badgeColor}`}>
                          {link.count} pending
                        </span>
                      )}
                      <ChevronRight className="arrow-icon" size={20} />
                    </div>
                  </div>
                ))}
              </div>
            </section>

            {/* Current Settings Status Summary */}
            <section className="live-status-section glass-card">
              <div className="clock-widget-admin">
                <Clock size={36} className="clock-icon-rotating-admin" />
                <h2 className="clock-time-admin">
                  {systemTime.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true })}
                </h2>
                <p className="clock-label-admin">CURRENT OFFICE TIME</p>
              </div>

              <div className="settings-summary-list">
                <div className="summary-list-header">
                  <Compass size={18} />
                  <span>Portal Health Summary</span>
                </div>
                <div className="summary-row">
                  <span>Backend Server Status:</span>
                  <span className="text-success-glow">ONLINE</span>
                </div>
                <div className="summary-row">
                  <span>GPS Geo-Fencing:</span>
                  <span className="text-cyan-glow">ACTIVE (Radius: 200m)</span>
                </div>
                <div className="summary-row">
                  <span>Pending Tasks:</span>
                  <span>{stats.pendingEmployees + stats.pendingLeaves + stats.pendingExceptions} Requests</span>
                </div>
              </div>
            </section>
          </div>
        </>
      )}
    </div>
  );
};

export default AdminDashboard;
