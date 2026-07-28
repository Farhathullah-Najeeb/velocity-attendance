import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import Navbar from './components/Navbar';

// Pages
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import LeaveManagement from './pages/LeaveManagement';
import AttendanceHistory from './pages/AttendanceHistory';
import Profile from './pages/Profile';
import EmployeeManagement from './pages/EmployeeManagement';
import AdminLeaveManagement from './pages/AdminLeaveManagement';
import AttendanceExceptions from './pages/AttendanceExceptions';
import HolidaysSettings from './pages/HolidaysSettings';
import AdminReports from './pages/AdminReports';

const AppLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return (
    <div className="app-container">
      <Navbar />
      <main className="main-content">
        {children}
      </main>
    </div>
  );
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          
          <Route 
            path="/" 
            element={
              <ProtectedRoute>
                <AppLayout>
                  <Dashboard />
                </AppLayout>
              </ProtectedRoute>
            } 
          />

          <Route 
            path="/leaves" 
            element={
              <ProtectedRoute allowedRoles={['EMPLOYEE']}>
                <AppLayout>
                  <LeaveManagement />
                </AppLayout>
              </ProtectedRoute>
            } 
          />

          <Route 
            path="/history" 
            element={
              <ProtectedRoute allowedRoles={['EMPLOYEE']}>
                <AppLayout>
                  <AttendanceHistory />
                </AppLayout>
              </ProtectedRoute>
            } 
          />

          <Route 
            path="/profile" 
            element={
              <ProtectedRoute>
                <AppLayout>
                  <Profile />
                </AppLayout>
              </ProtectedRoute>
            } 
          />

          {/* Admin Protected Routes */}
          <Route 
            path="/employees" 
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'SUPER_ADMIN']}>
                <AppLayout>
                  <EmployeeManagement />
                </AppLayout>
              </ProtectedRoute>
            } 
          />

          <Route 
            path="/admin-leaves" 
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'SUPER_ADMIN']}>
                <AppLayout>
                  <AdminLeaveManagement />
                </AppLayout>
              </ProtectedRoute>
            } 
          />

          <Route 
            path="/exceptions" 
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'SUPER_ADMIN']}>
                <AppLayout>
                  <AttendanceExceptions />
                </AppLayout>
              </ProtectedRoute>
            } 
          />

          <Route 
            path="/settings-holidays" 
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'SUPER_ADMIN']}>
                <AppLayout>
                  <HolidaysSettings />
                </AppLayout>
              </ProtectedRoute>
            } 
          />

          <Route 
            path="/reports" 
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'SUPER_ADMIN']}>
                <AppLayout>
                  <AdminReports />
                </AppLayout>
              </ProtectedRoute>
            } 
          />

          {/* Catch-all Redirect */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
