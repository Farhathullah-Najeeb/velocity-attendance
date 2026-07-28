import React, { createContext, useContext, useState, useEffect } from 'react';
import api from '../services/api';
import type { IUser, ILoginResponse } from '../types';

interface AuthContextType {
  user: IUser | null;
  token: string | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<ILoginResponse>;
  register: (name: string, email: string, password: string, department: string) => Promise<void>;
  logout: () => void;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<IUser | null>(null);
  const [token, setToken] = useState<string | null>(localStorage.getItem('token'));
  const [loading, setLoading] = useState<boolean>(true);

  // Validate token on mount
  useEffect(() => {
    const bootstrapAuth = async () => {
      const savedToken = localStorage.getItem('token');
      if (savedToken) {
        try {
          const res = await api.get<IUser>('/auth/profile');
          setUser(res.data);
        } catch (error) {
          console.error('Failed to validate saved token:', error);
          localStorage.removeItem('token');
          setToken(null);
          setUser(null);
        }
      }
      setLoading(false);
    };
    bootstrapAuth();
  }, []);

  const login = async (email: string, password: string): Promise<ILoginResponse> => {
    setLoading(true);
    try {
      const res = await api.post<ILoginResponse>('/auth/login', { email, password });
      const { access_token } = res.data;

      // Store in local storage
      localStorage.setItem('token', access_token);
      setToken(access_token);
      
      // Get full profile to ensure all details are populated
      const profileRes = await api.get<IUser>('/auth/profile');
      setUser(profileRes.data);
      
      return res.data;
    } catch (error) {
      setUser(null);
      setToken(null);
      localStorage.removeItem('token');
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const register = async (name: string, email: string, password: string, department: string): Promise<void> => {
    await api.post('/employees/register', { name, email, password, department });
  };

  const logout = () => {
    localStorage.removeItem('token');
    setToken(null);
    setUser(null);
  };

  const refreshProfile = async () => {
    if (token) {
      try {
        const res = await api.get<IUser>('/auth/profile');
        setUser(res.data);
      } catch (err) {
        console.error('Failed to refresh profile:', err);
      }
    }
  };

  return (
    <AuthContext.Provider value={{ user, token, loading, login, register, logout, refreshProfile }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
