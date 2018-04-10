/*
 * \brief  Client-side Fiasco.OC specific CPU session interface
 * \author Stefan Kalkowski
 * \author Norman Feske
 * \date   2011-04-14
 */

/*
 * Copyright (C) 2011-2017 Genode Labs GmbH
 *
 * This file is part of the Genode OS framework, which is distributed
 * under the terms of the GNU Affero General Public License version 3.
 */

#ifndef _INCLUDE__FOC_NATIVE_CPU__CLIENT_H_
#define _INCLUDE__FOC_NATIVE_CPU__CLIENT_H_

#include <foc_native_cpu/foc_native_cpu.h>
#include <base/rpc_client.h>

namespace Genode { struct Foc_native_cpu_client; }


struct Genode::Foc_native_cpu_client : Rpc_client<Foc_native_cpu>
{
	explicit Foc_native_cpu_client(Capability<Native_cpu> cap)
	: Rpc_client<Foc_native_cpu>(static_cap_cast<Foc_native_cpu>(cap)) { }

	Native_capability task_cap() override { return call<Rpc_task_cap>(); }

	// START Modification for Checkpoint/Restore (rtcr)
	addr_t cap_map_info() override { return call<Rpc_get_cap_map_info>(); }

	void cap_map_info(addr_t addr) override { call<Rpc_set_cap_map_info>(addr); }

	void install(Native_capability cap, addr_t kcap) override { call<Rpc_install>(cap, kcap); }
	// END Modification for Checkpoint/Restore (rtcr)

	Foc_thread_state thread_state(Thread_capability cap) override {
		return call<Rpc_thread_state>(cap); }
};

#endif /* _INCLUDE__FOC_NATIVE_CPU__CLIENT_H_ */
