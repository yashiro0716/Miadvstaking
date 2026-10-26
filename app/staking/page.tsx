"use client";
import dynamic from "next/dynamic";
const StakingApp = dynamic(() => import("./StakingApp"), { ssr: false });
export default function Page() { return <StakingApp />; }
