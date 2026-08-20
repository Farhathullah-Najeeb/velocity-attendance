import React from 'react';
import { FileQuestion } from 'lucide-react';
import './EmptyState.css';

interface EmptyStateProps {
  icon?: React.ReactNode;
  title: string;
  description: string;
  action?: React.ReactNode;
}

const EmptyState: React.FC<EmptyStateProps> = ({ 
  icon = <FileQuestion size={48} strokeWidth={1.5} />, 
  title, 
  description, 
  action 
}) => {
  return (
    <div className="empty-state-container fade-in">
      <div className="empty-state-icon">
        {icon}
      </div>
      <h3 className="empty-state-title">{title}</h3>
      <p className="empty-state-description">{description}</p>
      {action && <div className="empty-state-action">{action}</div>}
    </div>
  );
};

export default EmptyState;
