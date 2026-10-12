import { useEffect, useMemo, useState } from "react";

type Role = "Quản lý" | "Phục vụ" | "Thu ngân";
type Screen =
  | "home"
  | "tables"
  | "menu"
  | "invoices"
  | "profile"
  | "order"
  | "payment"
  | "receipt"
  | "reports"
  | "staff"
  | "shifts"
  | "kitchen"
  | "notifications"
  | "categories";

type TableStatus = "Trống" | "Đang phục vụ" | "Đã đặt" | "Chờ thanh toán";
type TableData = { id: number; seats: number; status: TableStatus; total?: number; started?: string };
type Dish = { id: number; name: string; category: string; price: number; available: boolean; image: string };
type Cart = Record<number, number>;

const foodPhotos = [
  "https://images.unsplash.com/photo-1636474498689-27e2d3ecf8d7?auto=format&fit=crop&w=360&q=80",
  "https://images.unsplash.com/photo-1527997921830-de1cf1f9b430?auto=format&fit=crop&w=360&q=80",
  "https://images.unsplash.com/photo-1699670425934-b30d13e63fea?auto=format&fit=crop&w=360&q=80",
  "https://images.unsplash.com/photo-1542990254-7174ee186dd1?auto=format&fit=crop&w=360&q=80",
  "https://images.unsplash.com/photo-1708352547484-a80b913944c5?auto=format&fit=crop&w=360&q=80",
];

const initialTables: TableData[] = [
  { id: 1, seats: 4, status: "Đang phục vụ", total: 185000, started: "11:32" },
  { id: 2, seats: 2, status: "Trống" },
  { id: 3, seats: 6, status: "Chờ thanh toán", total: 320000, started: "11:08" },
  { id: 4, seats: 4, status: "Đã đặt" },
  { id: 5, seats: 4, status: "Trống" },
  { id: 6, seats: 8, status: "Đang phục vụ", total: 465000, started: "12:03" },
  { id: 7, seats: 2, status: "Trống" },
  { id: 8, seats: 4, status: "Trống" },
  { id: 9, seats: 6, status: "Đang phục vụ", total: 225000, started: "12:18" },
  { id: 10, seats: 4, status: "Đã đặt" },
  { id: 11, seats: 2, status: "Trống" },
  { id: 12, seats: 10, status: "Trống" },
];

const dishNames = [
  ["Cơm chiên hải sản", "Món chính", 65000],
  ["Phở bò đặc biệt", "Món chính", 55000],
  ["Gà chiên nước mắm", "Món chính", 75000],
  ["Trà đào cam sả", "Đồ uống", 30000],
  ["Nước suối", "Đồ uống", 15000],
  ["Gỏi cuốn tôm thịt", "Khai vị", 45000],
  ["Chả giò hải sản", "Khai vị", 55000],
  ["Bò lúc lắc", "Món chính", 95000],
  ["Cá kho tộ", "Món chính", 85000],
  ["Canh chua cá", "Món phụ", 65000],
  ["Rau muống xào tỏi", "Món phụ", 45000],
  ["Khoai tây chiên", "Món phụ", 40000],
  ["Cà phê sữa đá", "Đồ uống", 25000],
  ["Nước ép cam", "Đồ uống", 35000],
  ["Trà tắc", "Đồ uống", 22000],
  ["Chè khúc bạch", "Tráng miệng", 35000],
  ["Bánh flan", "Tráng miệng", 25000],
  ["Trái cây theo mùa", "Tráng miệng", 45000],
  ["Lẩu thái hải sản", "Món chính", 245000],
  ["Súp cua", "Khai vị", 40000],
] as const;

const dishes: Dish[] = dishNames.map((d, index) => ({
  id: index + 1,
  name: d[0],
  category: d[1],
  price: d[2],
  available: ![6, 16].includes(index),
  image: foodPhotos[index % foodPhotos.length],
}));

const formatMoney = (value: number) => `${new Intl.NumberFormat("vi-VN").format(value)}đ`;

const iconPaths: Record<string, string> = {
  home: "M3 11.5 12 4l9 7.5V21a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1z",
  tables: "M5 5h14v9H5zM8 14v5m8-5v5M3 19h6m6 0h6",
  menu: "M6 3h12a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2m3 5h6m-6 4h6m-6 4h4",
  receipt: "M6 3h12v19l-3-2-3 2-3-2-3 2zM9 8h6m-6 4h6m-6 4h4",
  user: "M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8m-7 9a7 7 0 0 1 14 0",
  bell: "M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9m-8 13h4",
  search: "m21 21-4.3-4.3m2.3-5.2a7.5 7.5 0 1 1-15 0 7.5 7.5 0 0 1 15 0",
  plus: "M12 5v14M5 12h14",
  minus: "M5 12h14",
  back: "m15 18-6-6 6-6",
  arrow: "m9 18 6-6-6-6",
  card: "M3 6h18v12H3zM3 10h18",
  chart: "M4 20V10m5 10V4m6 16v-7m5 7V7",
  staff: "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2m7-10a4 4 0 1 0 0-8 4 4 0 0 0 0 8m13 10v-2a4 4 0 0 0-3-3.87m-2-12a4 4 0 0 1 0 7.75",
  clock: "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20m0-14v5l3 2",
  chef: "M6 13a4 4 0 0 1 1-7.87A5 5 0 0 1 17 6a4 4 0 0 1 1 7v7H6zM9 16v4m6-4v4",
  category: "M4 4h6v6H4zm10 0h6v6h-6zM4 14h6v6H4zm10 0h6v6h-6z",
  check: "m5 12 4 4L19 6",
  logout: "M10 17l5-5-5-5m5 5H3m10-9h7a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1h-7",
  eye: "M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12m10 3a3 3 0 1 0 0-6 3 3 0 0 0 0 6",
  lock: "M5 11h14v10H5zm3 0V7a4 4 0 0 1 8 0v4",
};

function Icon({ name, size = 22 }: { name: string; size?: number }) {
  return (
    <svg aria-hidden="true" className="icon" width={size} height={size} viewBox="0 0 24 24">
      <path d={iconPaths[name] || iconPaths.menu} />
    </svg>
  );
}

function Button({
  children,
  onClick,
  variant = "primary",
  disabled = false,
  className = "",
}: {
  children: React.ReactNode;
  onClick?: () => void;
  variant?: "primary" | "secondary" | "ghost" | "danger";
  disabled?: boolean;
  className?: string;
}) {
  return (
    <button className={`button button-${variant} ${className}`} onClick={onClick} disabled={disabled}>
      {children}
    </button>
  );
}

function ScreenHeader({ title, subtitle, back }: { title: string; subtitle?: string; back?: () => void }) {
  return (
    <header className="screen-header">
      {back && (
        <button className="icon-button" onClick={back} aria-label="Quay lại">
          <Icon name="back" />
        </button>
      )}
      <div className="header-copy">
        <h1>{title}</h1>
        {subtitle && <p>{subtitle}</p>}
      </div>
    </header>
  );
}

function Badge({ status }: { status: string }) {
  const cls =
    status.includes("Trống") || status.includes("Đã thanh toán") || status.includes("Hoàn")
      ? "success"
      : status.includes("Chờ") || status.includes("Đã đặt")
        ? "warning"
        : status.includes("Hủy") || status.includes("Khóa")
          ? "danger"
          : "info";
  return <span className={`badge ${cls}`}>{status}</span>;
}

function BottomNav({ active, setScreen }: { active: Screen; setScreen: (s: Screen) => void }) {
  const items: [Screen, string, string][] = [
    ["home", "home", "Trang chủ"],
    ["tables", "tables", "Bàn ăn"],
    ["menu", "menu", "Thực đơn"],
    ["invoices", "receipt", "Hóa đơn"],
    ["profile", "user", "Cá nhân"],
  ];
  return (
    <nav className="bottom-nav" aria-label="Điều hướng chính">
      {items.map(([screen, icon, label]) => (
        <button key={screen} className={active === screen ? "active" : ""} onClick={() => setScreen(screen)}>
          <Icon name={icon} />
          <span>{label}</span>
        </button>
      ))}
    </nav>
  );
}

function App() {
  const [stage, setStage] = useState<"splash" | "login" | "app">("splash");
  const [role, setRole] = useState<Role>("Quản lý");
  const [screen, setScreen] = useState<Screen>("home");
  const [tables, setTables] = useState(initialTables);
  const [selectedTable, setSelectedTable] = useState(2);
  const [cart, setCart] = useState<Cart>({});
  const [revenue, setRevenue] = useState(4285000);
  const [paidCount, setPaidCount] = useState(26);
  const [toast, setToast] = useState("");
  const [paymentMethod, setPaymentMethod] = useState("Tiền mặt");
  const [showConfirm, setShowConfirm] = useState(false);
  const [lastPayment, setLastPayment] = useState({ amount: 320000, table: 3 });

  useEffect(() => {
    if (stage === "splash") {
      const timer = window.setTimeout(() => setStage("login"), 900);
      return () => window.clearTimeout(timer);
    }
  }, [stage]);

  useEffect(() => {
    if (toast) {
      const timer = window.setTimeout(() => setToast(""), 2400);
      return () => window.clearTimeout(timer);
    }
  }, [toast]);

  const activeTable = tables.find((t) => t.id === selectedTable)!;
  const cartTotal = useMemo(
    () => Object.entries(cart).reduce((sum, [id, quantity]) => sum + dishes.find((d) => d.id === +id)!.price * quantity, 0),
    [cart],
  );

  const navigate = (target: Screen) => {
    if (role !== "Quản lý" && ["reports", "staff", "shifts", "categories"].includes(target)) {
      setToast("Bạn không có quyền truy cập chức năng này");
      return;
    }
    if (target === "payment") {
      const payable = tables.find((table) => table.status === "Chờ thanh toán") || tables.find((table) => table.total);
      if (payable) setSelectedTable(payable.id);
    }
    setScreen(target);
  };

  const startOrder = (table: TableData) => {
    setSelectedTable(table.id);
    setCart({});
    if (table.status === "Chờ thanh toán") {
      setScreen("payment");
    } else {
      setScreen("order");
    }
  };

  const submitOrder = () => {
    if (!cartTotal) return;
    setTables((items) =>
      items.map((t) =>
        t.id === selectedTable ? { ...t, status: "Đang phục vụ", total: (t.total || 0) + cartTotal, started: t.started || "12:42" } : t,
      ),
    );
    setToast(activeTable.status === "Trống" ? "Tạo đơn thành công" : "Đã thêm món vào đơn");
    setCart({});
    setScreen("tables");
  };

  const completePayment = () => {
    const amount = activeTable.total || 0;
    setLastPayment({ amount, table: activeTable.id });
    setTables((items) => items.map((t) => (t.id === selectedTable ? { ...t, status: "Trống", total: undefined, started: undefined } : t)));
    setRevenue((value) => value + amount);
    setPaidCount((value) => value + 1);
    setShowConfirm(false);
    setToast("Thanh toán thành công");
    setScreen("receipt");
  };

  if (stage === "splash") {
    return (
      <main className="splash">
        <div className="brand-mark large"><Icon name="chef" size={42} /></div>
        <h1>Restaurant Manager</h1>
        <p>Quản lý nhẹ nhàng, phục vụ tận tâm</p>
        <div className="loader"><span /></div>
      </main>
    );
  }

  if (stage === "login") {
    return (
      <main className="login-page">
        <section className="login-brand">
          <div className="brand-mark"><Icon name="chef" size={30} /></div>
          <div><strong>Restaurant</strong><span>Manager</span></div>
        </section>
        <section className="login-card">
          <div className="eyebrow">CHÀO MỪNG TRỞ LẠI</div>
          <h1>Đăng nhập</h1>
          <p>Quản lý mọi hoạt động nhà hàng tại một nơi.</p>
          <label className="field-label">Tên đăng nhập</label>
          <div className="text-field"><Icon name="user" size={19} /><input defaultValue="quanly" aria-label="Tên đăng nhập" /></div>
          <label className="field-label">Mật khẩu</label>
          <div className="text-field"><Icon name="lock" size={19} /><input defaultValue="123456" type="password" aria-label="Mật khẩu" /><Icon name="eye" size={19} /></div>
          <label className="remember"><input type="checkbox" defaultChecked /> Ghi nhớ đăng nhập</label>
          <Button className="full" onClick={() => setStage("app")}>Đăng nhập</Button>
          <div className="demo-box">
            <strong>Tài khoản demo</strong>
            <div className="role-tabs">
              {(["Quản lý", "Phục vụ", "Thu ngân"] as Role[]).map((item) => (
                <button key={item} className={role === item ? "selected" : ""} onClick={() => setRole(item)}>{item}</button>
              ))}
            </div>
            <span>quanly / phucvu / thungan • Mật khẩu: 123456</span>
          </div>
        </section>
      </main>
    );
  }

  const renderScreen = () => {
    if (screen === "home") return <Dashboard role={role} revenue={revenue} paidCount={paidCount} tables={tables} navigate={navigate} />;
    if (screen === "tables") return <Tables tables={tables} select={startOrder} role={role} />;
    if (screen === "menu") return <Menu role={role} onOrder={() => { setSelectedTable(2); setScreen("order"); }} categories={() => setScreen("categories")} />;
    if (screen === "order") return <Order table={activeTable} cart={cart} setCart={setCart} total={cartTotal} submit={submitOrder} back={() => setScreen("tables")} />;
    if (screen === "invoices") return <Invoices tables={tables} open={(id) => { setSelectedTable(id); setScreen("payment"); }} />;
    if (screen === "payment") return <Payment table={activeTable} method={paymentMethod} setMethod={setPaymentMethod} confirm={() => setShowConfirm(true)} back={() => setScreen("invoices")} />;
    if (screen === "receipt") return <Receipt method={paymentMethod} payment={lastPayment} home={() => setScreen("home")} />;
    if (screen === "profile") return <Profile role={role} logout={() => setStage("login")} />;
    if (screen === "reports") return <Reports revenue={revenue} back={() => setScreen("home")} />;
    if (screen === "staff") return <Staff back={() => setScreen("home")} />;
    if (screen === "shifts") return <Shifts back={() => setScreen("home")} />;
    if (screen === "kitchen") return <Kitchen back={() => setScreen("home")} notify={setToast} />;
    if (screen === "categories") return <Categories back={() => setScreen("menu")} />;
    return <Notifications back={() => setScreen("home")} />;
  };

  return (
    <div className="app-bg">
      <main className="phone-shell">
        <div className="status-bar"><span>9:41</span><span>● ● ▰</span></div>
        <div className="screen-content">{renderScreen()}</div>
        {["home", "tables", "menu", "invoices", "profile"].includes(screen) && <BottomNav active={screen} setScreen={navigate} />}
        {toast && <div className="toast"><Icon name="check" size={18} />{toast}</div>}
        {showConfirm && (
          <div className="modal-layer">
            <section className="dialog">
              <div className="dialog-icon"><Icon name="card" /></div>
              <h2>Xác nhận thanh toán?</h2>
              <p>Hóa đơn {formatMoney(activeTable.total || 0)} qua {paymentMethod}. Thao tác này không thể hoàn tác.</p>
              <div className="dialog-actions">
                <Button variant="secondary" onClick={() => setShowConfirm(false)}>Hủy</Button>
                <Button onClick={completePayment}>Xác nhận</Button>
              </div>
            </section>
          </div>
        )}
      </main>
    </div>
  );
}

function Dashboard({ role, revenue, paidCount, tables, navigate }: { role: Role; revenue: number; paidCount: number; tables: TableData[]; navigate: (s: Screen) => void }) {
  const occupied = tables.filter((t) => t.status === "Đang phục vụ").length;
  const empty = tables.filter((t) => t.status === "Trống").length;
  const actions: [Screen, string, string][] = role === "Quản lý"
    ? [["tables", "tables", "Bàn ăn"], ["menu", "menu", "Thực đơn"], ["invoices", "receipt", "Hóa đơn"], ["staff", "staff", "Nhân viên"], ["shifts", "clock", "Ca làm"], ["reports", "chart", "Báo cáo"]]
    : role === "Phục vụ"
      ? [["tables", "tables", "Bàn ăn"], ["order", "plus", "Gọi món"], ["kitchen", "chef", "Theo dõi bếp"], ["notifications", "bell", "Thông báo"]]
      : [["invoices", "receipt", "Hóa đơn"], ["payment", "card", "Thanh toán"], ["notifications", "bell", "Thông báo"]];
  return (
    <div>
      <section className="hero">
        <div className="top-row">
          <div><span className="muted-light">Xin chào,</span><h1>{role === "Quản lý" ? "Minh Anh" : role === "Phục vụ" ? "Hoàng Nam" : "Thu Hà"}</h1></div>
          <button className="notification" onClick={() => navigate("notifications")}><Icon name="bell" /><i>3</i></button>
        </div>
        <p>Nhà hàng Hương Việt</p>
        <div className="date-pill">Thứ Hai, 16/06/2025</div>
      </section>
      <section className="content-pad dashboard-offset">
        <div className="section-title"><div><span>TỔNG QUAN HÔM NAY</span><h2>Hoạt động nhà hàng</h2></div><Badge status="Đang mở cửa" /></div>
        <div className="revenue-card">
          <div><span>Doanh thu hôm nay</span><strong>{formatMoney(revenue)}</strong><small>↑ 12,5% so với hôm qua</small></div>
          <div className="mini-chart">{[38, 54, 44, 70, 60, 88, 76].map((h, i) => <i key={i} style={{ height: `${h}%` }} />)}</div>
        </div>
        <div className="stats-grid">
          <article><span className="stat-icon green"><Icon name="receipt" size={19} /></span><strong>{paidCount}</strong><small>Đã thanh toán</small></article>
          <article><span className="stat-icon orange"><Icon name="tables" size={19} /></span><strong>{occupied}</strong><small>Đang phục vụ</small></article>
          <article><span className="stat-icon blue"><Icon name="check" size={19} /></span><strong>{empty}</strong><small>Bàn còn trống</small></article>
          <article><span className="stat-icon purple"><Icon name="clock" size={19} /></span><strong>5</strong><small>Đơn đang xử lý</small></article>
        </div>
        <div className="section-heading"><h2>Thao tác nhanh</h2></div>
        <div className="quick-grid">
          {actions.map(([s, icon, label]) => <button key={label} onClick={() => navigate(s)}><span><Icon name={icon} /></span>{label}</button>)}
        </div>
        <div className="section-heading"><h2>Hóa đơn gần đây</h2><button onClick={() => navigate("invoices")}>Xem tất cả</button></div>
        <div className="compact-list">
          <article><span className="order-avatar">B03</span><div><strong>HD-20250616-026</strong><small>12:36 • Thu Hà</small></div><div><strong>320.000đ</strong><Badge status="Chờ thu" /></div></article>
          <article><span className="order-avatar">B08</span><div><strong>HD-20250616-025</strong><small>12:18 • Thu Hà</small></div><div><strong>245.000đ</strong><Badge status="Đã thanh toán" /></div></article>
        </div>
      </section>
    </div>
  );
}

function Tables({ tables, select, role }: { tables: TableData[]; select: (t: TableData) => void; role: Role }) {
  const [filter, setFilter] = useState("Tất cả");
  const list = tables.filter((t) => filter === "Tất cả" || t.status === filter);
  return (
    <div className="content-pad">
      <ScreenHeader title="Bàn ăn" subtitle={`${tables.filter((t) => t.status === "Trống").length} bàn trống • 3 khu vực`} />
      <div className="search-field"><Icon name="search" size={19} /><input placeholder="Tìm theo mã bàn..." /></div>
      <div className="chips">{["Tất cả", "Trống", "Đang phục vụ", "Đã đặt", "Chờ thanh toán"].map((x) => <button className={filter === x ? "active" : ""} onClick={() => setFilter(x)} key={x}>{x}</button>)}</div>
      <div className="legend"><span><i className="dot success" />Trống</span><span><i className="dot info" />Phục vụ</span><span><i className="dot warning" />Đặt trước / Chờ thu</span></div>
      <div className="table-grid">
        {list.map((table) => (
          <button key={table.id} className={`table-card status-${table.status.replaceAll(" ", "-").toLowerCase()}`} onClick={() => select(table)}>
            <div className="table-top"><span>B{String(table.id).padStart(2, "0")}</span><Icon name="tables" size={21} /></div>
            <strong>{table.status}</strong>
            <small>{table.seats} chỗ {table.started ? `• ${table.started}` : ""}</small>
            {table.total && <b>{formatMoney(table.total)}</b>}
          </button>
        ))}
      </div>
      {role === "Quản lý" && <button className="fab" aria-label="Thêm bàn"><Icon name="plus" /></button>}
    </div>
  );
}

function Menu({ role, onOrder, categories }: { role: Role; onOrder: () => void; categories: () => void }) {
  const [category, setCategory] = useState("Tất cả");
  const [query, setQuery] = useState("");
  const [sort, setSort] = useState(false);
  const list = dishes.filter((d) => (category === "Tất cả" || d.category === category) && d.name.toLowerCase().includes(query.toLowerCase()));
  if (sort) list.sort((a, b) => a.price - b.price);
  return (
    <div className="content-pad">
      <ScreenHeader title="Thực đơn" subtitle={`${dishes.filter((d) => d.available).length} món đang kinh doanh`} />
      <div className="search-actions"><div className="search-field"><Icon name="search" size={19} /><input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Tìm món ăn..." /></div><button className={sort ? "filter active" : "filter"} onClick={() => setSort(!sort)}><Icon name="chart" size={19} /></button></div>
      <div className="chips">{["Tất cả", "Món chính", "Khai vị", "Đồ uống", "Tráng miệng"].map((x) => <button className={category === x ? "active" : ""} onClick={() => setCategory(x)} key={x}>{x}</button>)}</div>
      {role === "Quản lý" && <div className="management-banner"><div><strong>Quản lý danh mục</strong><span>5 danh mục • 20 món ăn</span></div><button onClick={categories}><Icon name="arrow" /></button></div>}
      <div className="dish-list">
        {list.map((dish) => (
          <article key={dish.id} className={!dish.available ? "unavailable" : ""}>
            <img src={dish.image} alt={dish.name} />
            <div><small>{dish.category.toUpperCase()}</small><strong>{dish.name}</strong><b>{formatMoney(dish.price)}</b>{!dish.available && <Badge status="Hết món" />}</div>
            <button onClick={onOrder} disabled={!dish.available}><Icon name={role === "Quản lý" ? "arrow" : "plus"} size={19} /></button>
          </article>
        ))}
      </div>
      {role === "Quản lý" && <button className="fab" aria-label="Thêm món"><Icon name="plus" /></button>}
    </div>
  );
}

function Order({ table, cart, setCart, total, submit, back }: { table: TableData; cart: Cart; setCart: React.Dispatch<React.SetStateAction<Cart>>; total: number; submit: () => void; back: () => void }) {
  const [category, setCategory] = useState("Tất cả");
  const update = (id: number, delta: number) => setCart((value) => {
    const next = Math.max(0, (value[id] || 0) + delta);
    const result = { ...value, [id]: next };
    if (!next) delete result[id];
    return result;
  });
  return (
    <div className="order-page">
      <div className="content-pad">
        <ScreenHeader title={`Gọi món • B${String(table.id).padStart(2, "0")}`} subtitle={table.status === "Trống" ? "Tạo đơn mới" : "Thêm món vào đơn hiện tại"} back={back} />
        <div className="search-field"><Icon name="search" size={19} /><input placeholder="Tìm món ăn..." /></div>
        <div className="chips">{["Tất cả", "Món chính", "Khai vị", "Đồ uống"].map((x) => <button className={category === x ? "active" : ""} onClick={() => setCategory(x)} key={x}>{x}</button>)}</div>
        <div className="order-dishes">
          {dishes.filter((d) => d.available && (category === "Tất cả" || d.category === category)).slice(0, 10).map((dish) => (
            <article key={dish.id}>
              <img src={dish.image} alt={dish.name} />
              <div><strong>{dish.name}</strong><span>{formatMoney(dish.price)}</span></div>
              {cart[dish.id] ? <div className="stepper"><button onClick={() => update(dish.id, -1)}><Icon name="minus" size={15} /></button><b>{cart[dish.id]}</b><button onClick={() => update(dish.id, 1)}><Icon name="plus" size={15} /></button></div> : <button className="add" onClick={() => update(dish.id, 1)}><Icon name="plus" size={18} /></button>}
            </article>
          ))}
        </div>
      </div>
      <div className="order-summary">
        <div><span>{Object.values(cart).reduce((a, b) => a + b, 0)} món đã chọn</span><strong>{formatMoney(total)}</strong></div>
        <Button disabled={!total} onClick={submit}>Xác nhận đơn <Icon name="arrow" size={18} /></Button>
      </div>
    </div>
  );
}

function Invoices({ tables, open }: { tables: TableData[]; open: (id: number) => void }) {
  const pending = tables.filter((t) => t.status === "Chờ thanh toán" || t.status === "Đang phục vụ");
  return (
    <div className="content-pad">
      <ScreenHeader title="Hóa đơn" subtitle="Theo dõi và thu tiền" />
      <div className="search-field"><Icon name="search" size={19} /><input placeholder="Mã hóa đơn hoặc mã bàn..." /></div>
      <div className="chips"><button className="active">Tất cả</button><button>Chưa thanh toán</button><button>Đã thanh toán</button><button>Đã hủy</button></div>
      <div className="summary-strip"><div><span>Chờ thanh toán</span><strong>{pending.length} hóa đơn</strong></div><b>{formatMoney(pending.reduce((s, t) => s + (t.total || 0), 0))}</b></div>
      <div className="invoice-list">
        {pending.map((t, i) => <article key={t.id} onClick={() => open(t.id)}><div className="invoice-head"><strong>HD-20250616-{String(26 - i).padStart(3, "0")}</strong><Badge status={t.status === "Chờ thanh toán" ? "Chờ thu" : "Chưa thanh toán"} /></div><div className="invoice-body"><span className="order-avatar">B{String(t.id).padStart(2, "0")}</span><div><span>Thời gian</span><strong>{t.started} • 16/06/2025</strong></div><div><span>Tổng tiền</span><b>{formatMoney(t.total || 0)}</b></div></div><button>Xem chi tiết <Icon name="arrow" size={17} /></button></article>)}
        {[245000, 185000, 420000].map((amount, i) => <article key={`paid-${i}`}><div className="invoice-head"><strong>HD-20250616-0{23 - i}</strong><Badge status="Đã thanh toán" /></div><div className="invoice-body"><span className="order-avatar">B0{8 - i}</span><div><span>Thời gian</span><strong>11:{42 - i * 8} • 16/06/2025</strong></div><div><span>Tổng tiền</span><b>{formatMoney(amount)}</b></div></div></article>)}
      </div>
    </div>
  );
}

function Payment({ table, method, setMethod, confirm, back }: { table: TableData; method: string; setMethod: (m: string) => void; confirm: () => void; back: () => void }) {
  const items = [{ name: "Cơm chiên hải sản", q: 2, price: 65000 }, { name: "Gà chiên nước mắm", q: 1, price: 75000 }, { name: "Trà đào cam sả", q: 2, price: 30000 }];
  return (
    <div className="content-pad payment-page">
      <ScreenHeader title="Thanh toán" subtitle={`HD-20250616-026 • B${String(table.id).padStart(2, "0")}`} back={back} />
      <section className="bill-card"><div className="bill-title"><span>CHI TIẾT HÓA ĐƠN</span><Badge status="Chưa thanh toán" /></div>{items.map((x) => <div className="bill-line" key={x.name}><div><strong>{x.name}</strong><span>{x.q} × {formatMoney(x.price)}</span></div><b>{formatMoney(x.q * x.price)}</b></div>)}<div className="bill-total"><span>Tổng thanh toán</span><strong>{formatMoney(table.total || 320000)}</strong></div></section>
      <h2 className="form-title">Phương thức thanh toán</h2>
      <div className="payment-methods">{["Tiền mặt", "Chuyển khoản", "QR thanh toán"].map((m) => <button key={m} className={method === m ? "selected" : ""} onClick={() => setMethod(m)}><span><Icon name={m === "Tiền mặt" ? "receipt" : "card"} /></span><div><strong>{m}</strong><small>{m === "Tiền mặt" ? "Nhận tiền tại quầy" : "Giao dịch mô phỏng"}</small></div><i /></button>)}</div>
      <Button className="full payment-cta" onClick={confirm}>Xác nhận thanh toán • {formatMoney(table.total || 320000)}</Button>
      <p className="secure-note"><Icon name="lock" size={15} /> Đây là giao dịch mô phỏng, không sử dụng tiền thật.</p>
    </div>
  );
}

function Receipt({ method, payment, home }: { method: string; payment: { amount: number; table: number }; home: () => void }) {
  return <div className="success-page"><div className="success-ring"><Icon name="check" size={42} /></div><span>THANH TOÁN THÀNH CÔNG</span><h1>{formatMoney(payment.amount)}</h1><p>Hóa đơn đã được thanh toán và bàn B{String(payment.table).padStart(2, "0")} đã chuyển về trạng thái trống.</p><section className="receipt-card"><div className="receipt-brand"><div className="brand-mark"><Icon name="chef" /></div><strong>Nhà hàng Hương Việt</strong></div><div><span>Mã hóa đơn</span><b>HD-20250616-026</b></div><div><span>Thời gian</span><b>16/06/2025 • 12:48</b></div><div><span>Phương thức</span><b>{method}</b></div><div><span>Thu ngân</span><b>Nguyễn Thu Hà</b></div></section><div className="receipt-actions"><Button variant="secondary">In biên lai</Button><Button variant="secondary">Chia sẻ</Button></div><Button className="full" onClick={home}>Về trang chủ</Button></div>;
}

function Reports({ revenue, back }: { revenue: number; back: () => void }) {
  return <div className="content-pad"><ScreenHeader title="Báo cáo doanh thu" subtitle="16/06/2025" back={back} /><div className="chips"><button className="active">Hôm nay</button><button>7 ngày</button><button>Tháng này</button><button>Tùy chọn</button></div><section className="report-hero"><span>TỔNG DOANH THU</span><strong>{formatMoney(revenue)}</strong><small>↑ 12,5% so với kỳ trước</small></section><div className="report-stats"><article><span>Tuần này</span><b>28,6tr</b></article><article><span>Tháng này</span><b>112,4tr</b></article><article><span>Hóa đơn</span><b>286</b></article><article><span>Trung bình</span><b>168.000đ</b></article></div><section className="chart-card"><div className="section-heading"><h2>Doanh thu theo ngày</h2><span>Đơn vị: triệu</span></div><div className="bar-chart">{[42, 58, 46, 74, 65, 90, 82].map((h, i) => <div key={i}><i style={{ height: `${h}%` }} /><span>T{2 + i}</span></div>)}</div></section><section className="chart-card"><h2>Món bán chạy</h2>{[["Phở bò đặc biệt", 86], ["Cơm chiên hải sản", 68], ["Gà chiên nước mắm", 52]].map(([name, qty], i) => <div className="rank" key={name}><b>{i + 1}</b><span>{name}</span><strong>{qty} phần</strong></div>)}</section></div>;
}

function Staff({ back }: { back: () => void }) {
  const people = [["NV001", "Nguyễn Minh Anh", "090 123 4567", "Quản lý", "Hoạt động"], ["NV002", "Trần Hoàng Nam", "091 234 5678", "Phục vụ", "Hoạt động"], ["NV003", "Nguyễn Thu Hà", "093 456 7890", "Thu ngân", "Hoạt động"], ["NV004", "Lê Quang Huy", "096 288 3102", "Phục vụ", "Đã khóa"]];
  return <div className="content-pad"><ScreenHeader title="Nhân viên" subtitle="8 tài khoản • 7 đang hoạt động" back={back} /><div className="search-field"><Icon name="search" size={19} /><input placeholder="Tìm tên hoặc mã nhân viên..." /></div><div className="staff-list">{people.map((p) => <article key={p[0]}><span className="avatar">{p[1].split(" ").at(-1)?.[0]}</span><div><small>{p[0]} • {p[2]}</small><strong>{p[1]}</strong><span>{p[3]}</span></div><Badge status={p[4]} /></article>)}</div><button className="fab"><Icon name="plus" /></button></div>;
}

function Shifts({ back }: { back: () => void }) {
  return <div className="content-pad"><ScreenHeader title="Ca làm việc" subtitle="Thứ Hai, 16/06/2025" back={back} /><div className="week-row">{["T2|16", "T3|17", "T4|18", "T5|19", "T6|20", "T7|21", "CN|22"].map((x, i) => <button className={i === 0 ? "active" : ""} key={x}>{x.split("|").map(v => <span key={v}>{v}</span>)}</button>)}</div><div className="shift-list">{[["Ca sáng", "06:00 – 14:00", "4 nhân viên", "Đang diễn ra"], ["Ca chiều", "14:00 – 22:00", "5 nhân viên", "Sắp tới"], ["Ca tối", "18:00 – 23:00", "3 nhân viên", "Sắp tới"]].map(x => <article key={x[0]}><div className="shift-time"><Icon name="clock" /><span>{x[1]}</span></div><div><strong>{x[0]}</strong><span>{x[2]}</span></div><Badge status={x[3]} /></article>)}</div><button className="fab"><Icon name="plus" /></button></div>;
}

function Kitchen({ back, notify }: { back: () => void; notify: (s: string) => void }) {
  const [done, setDone] = useState<number[]>([]);
  const jobs = [["Phở bò đặc biệt", "B01 • 2 phần", "12:36"], ["Gà chiên nước mắm", "B06 • 1 phần", "12:34"], ["Cơm chiên hải sản", "B09 • 3 phần", "12:31"], ["Gỏi cuốn tôm thịt", "B01 • 2 phần", "12:29"]];
  return <div className="content-pad"><ScreenHeader title="Theo dõi chế biến" subtitle={`${jobs.length - done.length} món đang chờ`} back={back} /><div className="kitchen-tabs"><button className="active">Chờ chế biến <b>4</b></button><button>Đang làm <b>3</b></button><button>Hoàn thành</button></div><div className="kitchen-list">{jobs.map((j, i) => <article className={done.includes(i) ? "done" : ""} key={j[0]}><div className="ticket-time"><span>{j[2]}</span><small>{i + 6} phút</small></div><div><strong>{j[0]}</strong><span>{j[1]}</span></div><Button variant={done.includes(i) ? "secondary" : "primary"} onClick={() => { setDone(v => [...v, i]); notify("Đã cập nhật trạng thái món"); }}>{done.includes(i) ? "Đã xong" : "Bắt đầu"}</Button></article>)}</div></div>;
}

function Categories({ back }: { back: () => void }) {
  return <div className="content-pad"><ScreenHeader title="Danh mục món" subtitle="5 danh mục đang sử dụng" back={back} /><div className="category-list">{[["Món chính", 8], ["Món khai vị", 3], ["Món phụ", 3], ["Đồ uống", 4], ["Tráng miệng", 3]].map(([name, count]) => <article key={name}><span><Icon name="category" /></span><div><strong>{name}</strong><small>{count} món đang liên kết</small></div><button><Icon name="arrow" /></button></article>)}</div><div className="info-box">Không thể xóa danh mục đang có món liên kết. Hãy chuyển món sang danh mục khác trước.</div><button className="fab"><Icon name="plus" /></button></div>;
}

function Notifications({ back }: { back: () => void }) {
  return <div className="content-pad"><ScreenHeader title="Thông báo" subtitle="3 thông báo chưa đọc" back={back} /><div className="notification-list">{[["chef", "Món đã hoàn thành", "Phở bò đặc biệt của bàn B01 đã sẵn sàng.", "2 phút"], ["receipt", "Thanh toán thành công", "Hóa đơn HD-025 đã thanh toán 245.000đ.", "18 phút"], ["tables", "Thay đổi trạng thái bàn", "Bàn B04 vừa được đặt trước lúc 18:30.", "32 phút"], ["bell", "Đơn hàng mới", "Bàn B09 vừa gửi đơn với 5 món.", "45 phút"]].map((n, i) => <article className={i < 3 ? "unread" : ""} key={n[1]}><span><Icon name={n[0]} /></span><div><strong>{n[1]}</strong><p>{n[2]}</p><small>{n[3]} trước</small></div>{i < 3 && <i />}</article>)}</div></div>;
}

function Profile({ role, logout }: { role: Role; logout: () => void }) {
  return <div><section className="profile-hero"><div className="avatar large">M</div><h1>Nguyễn Minh Anh</h1><p>@quanly • {role}</p><Badge status="Đang hoạt động" /></section><div className="content-pad profile-content"><section className="restaurant-card"><span className="brand-mark"><Icon name="chef" /></span><div><small>NHÀ HÀNG</small><strong>Hương Việt</strong><span>128 Nguyễn Huệ, Quận 1</span></div></section><div className="settings-list">{[["user", "Thông tin cá nhân"], ["lock", "Đổi mật khẩu"], ["home", "Thông tin nhà hàng"], ["bell", "Cài đặt thông báo"], ["menu", "Giao diện ứng dụng"]].map(x => <button key={x[1]}><Icon name={x[0]} /><span>{x[1]}</span><Icon name="arrow" size={18} /></button>)}</div><button className="logout-button" onClick={logout}><Icon name="logout" />Đăng xuất</button><p className="version">Restaurant Manager • Phiên bản demo 1.0<br />Dữ liệu sẽ mất khi tải lại ứng dụng</p></div></div>;
}

export default App;
