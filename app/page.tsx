"use client";

import dynamic from "next/dynamic";

const RewardsApp = dynamic(() => import("./RewardsApp"), { ssr: false });

export default function Page() {
  return <RewardsApp />;
}
