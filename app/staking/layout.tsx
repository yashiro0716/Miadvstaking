import type { Metadata, Viewport } from "next";
import Providers from "../providers";
import "../globals.css";
export const metadata: Metadata = { title: "ADV2.0 Staking", description: "Staking de AD2 en World Chain", applicationName: "ADV2.0 Staking" };
export const viewport: Viewport = { width: "device-width", initialScale: 1, themeColor: "#100d1b" };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="es"><body><Providers>{children}</Providers></body></html>; }
