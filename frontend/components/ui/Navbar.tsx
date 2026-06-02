"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { Network, BookOpen, Play, Search } from "lucide-react";

const NAV = [
  { href: "/",         label: "Explorer",  icon: Network  },
  { href: "/learn",    label: "Learn",     icon: BookOpen },
  { href: "/simulate", label: "Simulate",  icon: Play     },
  { href: "/retrieve", label: "Retrieve",  icon: Search   },
];

export default function Navbar() {
  const path = usePathname();

  return (
    <nav
      className="flex items-center gap-6 px-5 py-3 border-b flex-shrink-0 z-30"
      style={{ background: "var(--surface)", borderColor: "var(--border)" }}
    >
      <Link href="/" className="flex items-center gap-2 mr-2">
        <span
          className="text-xs font-bold tracking-widest px-2 py-1 rounded"
          style={{ background: "color-mix(in srgb, var(--accent) 12%, transparent)", color: "var(--accent)" }}
        >
          UCKB
        </span>
        <span className="text-xs hidden sm:block" style={{ color: "var(--muted)" }}>
          Universal Communication Knowledge Base
        </span>
      </Link>

      <div className="flex items-center gap-1">
        {NAV.map(({ href, label, icon: Icon }) => {
          const active = href === "/" ? path === "/" : path.startsWith(href);
          return (
            <Link
              key={href}
              href={href}
              className={cn(
                "flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-medium transition-all",
                active
                  ? "bg-[color-mix(in_srgb,var(--accent)_10%,transparent)]"
                  : "hover:bg-black/5"
              )}
              style={{
                color: active ? "var(--accent)" : "var(--muted)",
              }}
            >
              <Icon size={12} />
              {label}
            </Link>
          );
        })}
      </div>

      <div className="ml-auto flex items-center gap-3">
        <a
          href="https://github.com"
          target="_blank"
          rel="noopener noreferrer"
          className="text-[10px] font-mono transition-colors hover:underline"
          style={{ color: "var(--muted)" }}
        >
          GitHub →
        </a>
        <span className="text-[10px] font-mono" style={{ color: "var(--muted)", opacity: 0.6 }}>v0.1</span>
      </div>
    </nav>
  );
}
