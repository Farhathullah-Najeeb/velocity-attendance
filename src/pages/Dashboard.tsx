import React from 'react';
import EmployeeDashboard from './EmployeeDashboard';
import { useAuth } from '../context/AuthContext';
import AdminDashboard from './AdminDashboard';

const Dashboard: React.FC = () => {
  const { user } = useAuth();

  if (!user) return null;

  const isAdmin = user.role === 'ADMIN' || user.role === 'SUPER_ADMIN';

  return isAdmin ? <AdminDashboard /> : <EmployeeDashboard />;
};

export default Dashboard;
