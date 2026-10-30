package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"
)

const goroutineDumpTimeout = 90 * time.Second

type podList struct {
	Items []pod `json:"items"`
}

type pod struct {
	Metadata struct {
		Name      string            `json:"name"`
		Namespace string            `json:"namespace"`
		Labels    map[string]string `json:"labels"`
	} `json:"metadata"`
	Spec struct {
		NodeName string `json:"nodeName"`
	} `json:"spec"`
	Status struct {
		ContainerStatuses []struct {
			Ready        bool `json:"ready"`
			RestartCount int  `json:"restartCount"`
		} `json:"containerStatuses"`
	} `json:"status"`
}

func (p pod) unhealthy() bool {
	if len(p.Status.ContainerStatuses) == 0 {
		return true
	}
	for _, c := range p.Status.ContainerStatuses {
		if !c.Ready || c.RestartCount > 0 {
			return true
		}
	}
	return false
}

func (p pod) restarts() int {
	total := 0
	for _, c := range p.Status.ContainerStatuses {
		total += c.RestartCount
	}
	return total
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: go run collect-test-diagnostics.go <test-dir>")
		os.Exit(1)
	}
	namespace := subjectNamespace(os.Args[1])

	group("Nodes", "kubectl", "get", "nodes", "-o", "wide")
	group("Pods", "kubectl", "get", "pods", "--all-namespaces", "-o", "wide")
	group("Events", "kubectl", "get", "events", "--all-namespaces", "--sort-by=.lastTimestamp")

	pods, err := listPods()
	if err != nil {
		fmt.Println("unable to list pods:", err)
		return
	}

	for _, p := range pods {
		name := p.Metadata.Namespace + "/" + p.Metadata.Name
		if p.unhealthy() {
			group("Describe "+name, "kubectl", "describe", "pod", "-n", p.Metadata.Namespace, p.Metadata.Name)
			group("Previous logs "+name, "kubectl", "logs", "-n", p.Metadata.Namespace, p.Metadata.Name, "--all-containers", "--previous")
		}
		if p.unhealthy() || p.Metadata.Namespace == namespace {
			group("Logs "+name, "kubectl", "logs", "-n", p.Metadata.Namespace, p.Metadata.Name, "--all-containers")
		}
	}

	for _, p := range pods {
		if p.Metadata.Labels["app.kubernetes.io/name"] == "beyla" {
			dumpGoroutines(p, "beyla")
		}
	}
}

func subjectNamespace(testDir string) string {
	out, err := exec.Command("yq", "eval", `.subject.namespace // ""`, testDir+"/test-plan.yaml").Output()
	if ns := strings.TrimSpace(string(out)); err == nil && ns != "" {
		return ns
	}
	return "default"
}

func listPods() ([]pod, error) {
	out, err := exec.Command("kubectl", "get", "pods", "--all-namespaces", "-o", "json").Output()
	if err != nil {
		return nil, err
	}
	var list podList
	if err := json.Unmarshal(out, &list); err != nil {
		return nil, err
	}
	return list.Items, nil
}

func getPod(p pod) (pod, error) {
	out, err := exec.Command("kubectl", "get", "pod", "-n", p.Metadata.Namespace, p.Metadata.Name, "-o", "json").Output()
	if err != nil {
		return pod{}, err
	}
	var latest pod
	err = json.Unmarshal(out, &latest)
	return latest, err
}

// Go processes print every goroutine's stack on SIGQUIT and exit; the dump is then in the previous container's logs.
func dumpGoroutines(p pod, process string) {
	name := p.Metadata.Namespace + "/" + p.Metadata.Name
	fmt.Printf("::group::Goroutine dump %s\n", name)
	defer fmt.Println("::endgroup::")

	before := p.restarts()
	if out, err := exec.Command("docker", "exec", p.Spec.NodeName, "pkill", "-QUIT", "-x", process).CombinedOutput(); err != nil {
		fmt.Printf("unable to signal %s on node %s: %v %s\n", process, p.Spec.NodeName, err, out)
		return
	}

	deadline := time.Now().Add(goroutineDumpTimeout)
	for time.Now().Before(deadline) {
		if latest, err := getPod(p); err == nil && latest.restarts() > before {
			run("kubectl", "logs", "-n", p.Metadata.Namespace, p.Metadata.Name, "--all-containers", "--previous")
			return
		}
		time.Sleep(2 * time.Second)
	}
	fmt.Printf("%s did not restart within %s\n", name, goroutineDumpTimeout)
}

func group(title string, name string, args ...string) {
	fmt.Printf("::group::%s\n", title)
	run(name, args...)
	fmt.Println("::endgroup::")
}

func run(name string, args ...string) {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stdout
	if err := cmd.Run(); err != nil {
		fmt.Printf("%s %s: %v\n", name, strings.Join(args, " "), err)
	}
}
