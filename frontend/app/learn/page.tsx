"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import RoleSelector from "@/components/learn/RoleSelector";
import ProtocolSwimlane from "@/components/learn/ProtocolSwimlane";
import { useGraphStore } from "@/stores/graph-store";

export default function LearnPage() {
  const { role, setRole } = useGraphStore();
  const [showRoleSelector, setShowRoleSelector] = useState(!role);

  const handleRoleSelect = (r: Parameters<typeof setRole>[0]) => {
    setRole(r);
    setShowRoleSelector(false);
  };

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      <AnimatePresence mode="wait">
        {showRoleSelector ? (
          <motion.div
            key="role"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="flex-1 flex items-center justify-center p-8"
          >
            <RoleSelector onSelect={handleRoleSelect} />
          </motion.div>
        ) : (
          <motion.div
            key="path"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex-1 flex flex-col overflow-hidden"
          >
            {/* Header */}
            <div
              className="flex items-center justify-between px-6 py-4 border-b"
              style={{ borderColor: "var(--border)" }}
            >
              <div>
                <h1 className="text-sm font-semibold text-[#e2e4f0]">
                  Learning Path
                </h1>
                <p className="text-xs text-[#6b7280] mt-0.5">
                  Follow the prerequisite chain to build communication mastery
                </p>
              </div>
              <button
                type="button"
                onClick={() => setShowRoleSelector(true)}
                className="text-xs text-[#6b7280] hover:text-[#22d3ee] transition-colors px-3 py-1.5 rounded-md border border-[var(--border)] bg-[var(--surface)]"
              >
                Change Role
              </button>
            </div>

            <div className="flex-1 overflow-auto p-6">
              <ProtocolSwimlane />
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
