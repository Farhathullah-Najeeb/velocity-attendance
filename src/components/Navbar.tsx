import React, { useState } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { 
  LayoutDashboard, 
  CalendarDays, 
  History, 
  UserCircle, 
  LogOut,
  Users,
  AlertTriangle,
  Settings,
  FileSpreadsheet,
  Menu,
  X
} from 'lucide-react';
import logoBlack from '../assets/logo_black.png';
import './Navbar.css';

const Navbar: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  if (!user) return null;

  const isAdmin = user.role === 'ADMIN' || user.role === 'SUPER_ADMIN';

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen);
  };

  const closeMobileMenu = () => {
    setIsMobileMenuOpen(false);
  };

  const navLinks = (
    <>
      {/* Universal Dashboard Link */}
      <NavLink 
        to="/" 
        className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
        onClick={closeMobileMenu}
      >
        <LayoutDashboard size={20} />
        <span>Dashboard</span>
      </NavLink>

      {/* Admin Navigation Links */}
      {isAdmin ? (
        <>
          <NavLink 
            to="/employees" 
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            onClick={closeMobileMenu}
          >
            <Users size={20} />
            <span>Employees</span>
          </NavLink>

          <NavLink 
            to="/admin-leaves" 
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            onClick={closeMobileMenu}
          >
            <CalendarDays size={20} />
            <span>Leave Requests</span>
          </NavLink>

          <NavLink 
            to="/exceptions" 
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            onClick={closeMobileMenu}
          >
            <AlertTriangle size={20} />
            <span>Exceptions</span>
          </NavLink>

          <NavLink 
            to="/settings-holidays" 
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            onClick={closeMobileMenu}
          >
            <Settings size={20} />
            <span>Holidays & Settings</span>
          </NavLink>

          <NavLink 
            to="/reports" 
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            onClick={closeMobileMenu}
          >
            <FileSpreadsheet size={20} />
            <span>Reports</span>
          </NavLink>
        </>
      ) : (
        /* Employee Navigation Links */
        <>
          <NavLink 
            to="/leaves" 
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            onClick={closeMobileMenu}
          >
            <CalendarDays size={20} />
            <span>Leave Management</span>
          </NavLink>

          <NavLink 
            to="/history" 
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            onClick={closeMobileMenu}
          >
            <History size={20} />
            <span>My History</span>
          </NavLink>
        </>
      )}

      {/* Universal Profile Link */}
      <NavLink 
        to="/profile" 
        className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
        onClick={closeMobileMenu}
      >
        <UserCircle size={20} />
        <span>My Profile</span>
      </NavLink>
    </>
  );

  return (
    <>
      {/* Mobile Top Navbar */}
      <header className="mobile-navbar">
        <div className="mobile-navbar-brand">
          <img src={logoBlack} alt="Velocity Home Logo" className="mobile-logo-img" />
        </div>
        <button className="mobile-menu-toggle" onClick={toggleMobileMenu} aria-label="Toggle menu">
          {isMobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </header>

      {/* Desktop Sidebar / Mobile Drawer Container */}
      <aside className={`sidebar-container ${isMobileMenuOpen ? 'mobile-open' : ''}`}>
        <div className="sidebar-header">
          <img src={logoBlack} alt="Velocity Home Logo" className="sidebar-logo-img" />
        </div>

        <div className="user-profile-badge">
          <div className="user-avatar">
            {user.name.charAt(0).toUpperCase()}
          </div>
          <div className="user-info">
            <h4 className="user-name">{user.name}</h4>
            <span className="user-dept">{isAdmin ? user.role : (user.department || 'EMPLOYEE')}</span>
          </div>
        </div>

        <nav className="sidebar-nav">
          {navLinks}
        </nav>

        <div className="sidebar-footer">
          <button className="logout-btn" onClick={handleLogout}>
            <LogOut size={20} />
            <span>Log Out</span>
          </button>
        </div>
      </aside>

      {/* Mobile Bottom Navigation Bar */}
      <nav className="mobile-bottom-nav">
        <NavLink to="/" className={({ isActive }) => `bottom-nav-item ${isActive ? 'active' : ''}`}>
          <LayoutDashboard size={22} />
          <span>Home</span>
        </NavLink>
        {isAdmin ? (
          <>
            <NavLink to="/employees" className={({ isActive }) => `bottom-nav-item ${isActive ? 'active' : ''}`}>
              <Users size={22} />
              <span>Employees</span>
            </NavLink>
            <NavLink to="/admin-leaves" className={({ isActive }) => `bottom-nav-item ${isActive ? 'active' : ''}`}>
              <CalendarDays size={22} />
              <span>Leaves</span>
            </NavLink>
            <button type="button" className="bottom-nav-item" onClick={toggleMobileMenu}>
              <Menu size={22} />
              <span>More</span>
            </button>
          </>
        ) : (
          <>
            <NavLink to="/leaves" className={({ isActive }) => `bottom-nav-item ${isActive ? 'active' : ''}`}>
              <CalendarDays size={22} />
              <span>Leaves</span>
            </NavLink>
            <NavLink to="/history" className={({ isActive }) => `bottom-nav-item ${isActive ? 'active' : ''}`}>
              <History size={22} />
              <span>History</span>
            </NavLink>
            <NavLink to="/profile" className={({ isActive }) => `bottom-nav-item ${isActive ? 'active' : ''}`}>
              <UserCircle size={22} />
              <span>Profile</span>
            </NavLink>
          </>
        )}
      </nav>

      {/* Backdrop for mobile menu */}
      {isMobileMenuOpen && <div className="mobile-backdrop" onClick={closeMobileMenu}></div>}
    </>
  );
};

export default Navbar;
