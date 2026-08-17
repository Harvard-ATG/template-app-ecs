'use client';

import React from 'react';

interface CardProps {
  title: string;
  children: React.ReactNode;
  className?: string;
}

export function Card({ title, children, className = '' }: CardProps) {
  return (
    <div className={`bg-white rounded-lg border border-gray-200 shadow-md hover:shadow-lg transition-shadow p-6 ${className}`}>
      <h3 className="text-lg font-bold text-gray-900 mb-4 pb-2 border-b border-gray-100">{title}</h3>
      <div className="space-y-3">
        {children}
      </div>
    </div>
  );
}
