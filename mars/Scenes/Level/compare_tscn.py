import re

def parse_tscn(file_path):
    ext_resources = {}
    nodes = {}
    current_node = None
    
    # 用于匹配 ext_resource 和 node 的正则
    ext_res_pattern = re.compile(r'\[ext_resource type="([^"]+)" uid="([^"]+)" path="([^"]+)" id="([^"]+)"\]')
    node_pattern = re.compile(r'\[node name="([^"]+)" type="([^"]+)"')

    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            
            # 解析外部资源
            ext_match = ext_res_pattern.match(line)
            if ext_match:
                res_type, uid, path, res_id = ext_match.groups()
                ext_resources[res_id] = {"type": res_type, "uid": uid, "path": path, "line": line}
                continue
                
            # 如果某一行写坏了（比如 [ext_resource type="Texture2D" 没写完）
            if line.startswith('[ext_resource') and not line.endswith(']'):
                ext_resources[f"ERROR_LINE__{line[:20]}"] = {"type": "损坏的资源行", "uid": "未知", "path": "未知", "line": line}

            # 解析节点
            node_match = node_pattern.match(line)
            if node_match:
                node_name, node_type = node_match.groups()
                current_node = node_name
                nodes[current_node] = {"type": node_type, "properties": []}
                continue
                
            # 记录节点属性
            if current_node and line and not line.startswith('['):
                nodes[current_node]["properties"].append(line)
                
    return ext_resources, nodes

def compare_tscn_files(file1, file2):
    print(f"=== 开始对比: {file1} VS {file2} ===\n")
    
    ext1, nodes1 = parse_tscn(file1)
    ext2, nodes2 = parse_tscn(file2)
    
    # 1. 对比外部资源 (ext_resource)
    print("--- 1. 外部资源 (ext_resource) 对比 ---")
    all_res_ids = set(ext1.keys()).union(set(ext2.keys()))
    has_ext_diff = False
    
    for res_id in sorted(all_res_ids):
        if res_id not in ext1:
            print(f"[仅在 {file2} 中存在] ID: {res_id} -> {ext2[res_id]['path']}")
            has_ext_diff = True
        elif res_id not in ext2:
            print(f"[仅在 {file1} 中存在 (可能是错误源)] ID: {res_id} -> {ext1[res_id]['line']}")
            has_ext_diff = True
        else:
            # 两个文件都有这个 ID，对比路径和 UID 是否一致
            if ext1[res_id]['path'] != ext2[res_id]['path'] or ext1[res_id]['uid'] != ext2[res_id]['uid']:
                print(f"[资源冲突] ID 为 '{res_id}' 的资源不一致：")
                print(f"  {file1}: path={ext1[res_id]['path']}, uid={ext1[res_id]['uid']}")
                print(f"  {file2}: path={ext2[res_id]['path']}, uid={ext2[res_id]['uid']}")
                has_ext_diff = True
                
    if not has_ext_diff:
        print("两边的外部资源 ID 和路径完全一致。")
        
    print("\n" + "="*40 + "\n")
    
    # 2. 对比节点结构 (node)
    print("--- 2. 节点结构 (node) 对比 ---")
    all_nodes = set(nodes1.keys()).union(set(nodes2.keys()))
    has_node_diff = False
    
    for node_name in all_nodes:
        if node_name not in nodes1:
            print(f"[仅在 {file2} 中存在节点]: {node_name} ({nodes2[node_name]['type']})")
            has_node_diff = True
        elif node_name not in nodes2:
            print(f"[仅在 {file1} 中存在节点]: {node_name} ({nodes1[node_name]['type']})")
            has_node_diff = True
            
    if not has_node_diff:
        print("两边的节点层级命名完全一致。")

if __name__ == "__main__":
    # 在这里填入你的两个文件名
    file_mine = "prologue.tscn"
    file_teammate = "prologue2.tscn"
    
    compare_tscn_files(file_mine, file_teammate)