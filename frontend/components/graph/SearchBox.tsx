"use client";
import { useState, useEffect, useCallback } from "react";
import { Search, X } from "lucide-react";
import { useGraphStore } from "@/stores/graph-store";
import { SearchResult } from "@/lib/types";
import { colorForDomain } from "@/lib/domain-colors";

interface SearchBoxProps {
  onSelect: (id: string) => void;
}

export default function SearchBox({ onSelect }: SearchBoxProps) {
  const { searchQuery, setSearchQuery, setHighlightedIds, nodes } = useGraphStore();
  const [results, setResults] = useState<SearchResult[]>([]);
  const [open, setOpen] = useState(false);

  const search = useCallback(
    async (q: string) => {
      if (!q.trim()) {
        setResults([]);
        setHighlightedIds(new Set());
        return;
      }

      // Client-side fuzzy search over loaded stubs first
      const lower = q.toLowerCase();
      const clientHits = nodes
        .filter((n) => n.name.toLowerCase().includes(lower))
        .slice(0, 8)
        .map((n) => ({ ...n, score: 1 }));

      setResults(clientHits);
      setHighlightedIds(new Set(clientHits.map((r) => r.id)));

      // Also hit API for deeper search
      try {
        const resp = await fetch(`/api/search?q=${encodeURIComponent(q)}`);
        if (resp.ok) {
          const apiResults: SearchResult[] = await resp.json();
          setResults(apiResults.slice(0, 10));
          setHighlightedIds(new Set(apiResults.map((r) => r.id)));
        }
      } catch {
        // ignore — client results already shown
      }
    },
    [nodes, setHighlightedIds]
  );

  useEffect(() => {
    const tid = setTimeout(() => search(searchQuery), 250);
    return () => clearTimeout(tid);
  }, [searchQuery, search]);

  const clear = () => {
    setSearchQuery("");
    setResults([]);
    setHighlightedIds(new Set());
    setOpen(false);
  };

  return (
    <div className="relative">
      <div
        className="flex items-center gap-2 px-3 py-2 rounded-lg border text-xs"
        style={{ borderColor: "var(--border)", background: "var(--surface-2)" }}
      >
        <Search size={12} className="text-[#6b7280] flex-shrink-0" />
        <input
          className="flex-1 bg-transparent text-[#e2e4f0] placeholder-[#6b7280] outline-none"
          placeholder="Find techniques..."
          value={searchQuery}
          onChange={(e) => {
            setSearchQuery(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
        />
        {searchQuery && (
          <button onClick={clear}>
            <X size={12} className="text-[#6b7280] hover:text-[#e2e4f0]" />
          </button>
        )}
      </div>

      {open && results.length > 0 && (
        <div
          className="absolute top-full left-0 right-0 mt-1 rounded-lg border shadow-xl z-50 overflow-hidden"
          style={{ borderColor: "var(--border)", background: "var(--surface)" }}
        >
          {results.map((r) => (
            <button
              key={r.id}
              onClick={() => {
                onSelect(r.id);
                setOpen(false);
              }}
              className="w-full flex items-center gap-2 px-3 py-2 text-xs text-left hover:bg-white/5 transition-colors"
            >
              <span
                className="w-2 h-2 rounded-full flex-shrink-0"
                style={{ background: colorForDomain(r.domain) }}
              />
              <span className="flex-1 truncate text-[#e2e4f0]">{r.name}</span>
              <span className="text-[#6b7280] truncate max-w-[80px]">{r.domain.split(" ")[0]}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
