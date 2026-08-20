import React from 'react';
import './SkeletonLoader.css';

interface SkeletonLoaderProps {
  type: 'table' | 'card' | 'stats' | 'form';
  count?: number;
}

const SkeletonLoader: React.FC<SkeletonLoaderProps> = ({ type, count = 1 }) => {
  const renderSkeletons = () => {
    const items = [];
    for (let i = 0; i < count; i++) {
      if (type === 'table') {
        items.push(
          <div key={i} className="skeleton-row">
            <div className="skeleton-cell w-1/4"></div>
            <div className="skeleton-cell w-1/4"></div>
            <div className="skeleton-cell w-1/4"></div>
            <div className="skeleton-cell w-1/4"></div>
          </div>
        );
      } else if (type === 'card') {
        items.push(
          <div key={i} className="skeleton-card glass-card">
            <div className="skeleton-text w-3/4 mb-2"></div>
            <div className="skeleton-text w-1/2 mb-4"></div>
            <div className="skeleton-text w-full"></div>
            <div className="skeleton-text w-full mt-2"></div>
          </div>
        );
      } else if (type === 'stats') {
        items.push(
          <div key={i} className="skeleton-stat stat-card glass-card">
            <div className="skeleton-text w-1/2 mb-4"></div>
            <div className="skeleton-title w-3/4 mb-2"></div>
            <div className="skeleton-text w-1/4"></div>
          </div>
        );
      } else if (type === 'form') {
        items.push(
          <div key={i} className="skeleton-form-group">
            <div className="skeleton-text w-1/4 mb-2"></div>
            <div className="skeleton-input w-full"></div>
          </div>
        );
      }
    }
    return items;
  };

  return (
    <div className={`skeleton-container skeleton-${type}`}>
      {renderSkeletons()}
    </div>
  );
};

export default SkeletonLoader;
